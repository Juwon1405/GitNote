#!/usr/bin/env python3
"""
mft_timestomp_detector.py — Detect $SI < $FN timestamp anomalies in MFT exports

Reads an MFTECmd CSV export (Eric Zimmerman) or analyzeMFT CSV and surfaces
files where $STANDARD_INFORMATION timestamps predate $FILE_NAME timestamps —
the canonical signature of T1070.006 (Indicator Removal — Timestomp).

Detection logic:
  - $SI.created  < $FN.created  - tolerance  → timestomp (created)
  - $SI.modified < $FN.modified - tolerance  → timestomp (modified)
  - Severity escalates if delta > 1 hour
  - Severity escalates further if file is an executable

Usage:
    # Generate MFT CSV first
    MFTECmd.exe -f \\$MFT --csv outdir --csvf mft.csv

    # Then run this:
    python3 mft_timestomp_detector.py mft.csv
    python3 mft_timestomp_detector.py mft.csv --tolerance 1 --executables-only
    python3 mft_timestomp_detector.py mft.csv --json > findings.json

The MFTECmd CSV columns we use:
    FullPath
    Created0x10        ($SI.created)
    Created0x30        ($FN.created)
    LastModified0x10   ($SI.modified)
    LastModified0x30   ($FN.modified)

Author: Yushin (https://github.com/Juwon1405)
License: CC BY 4.0
Reference: https://github.com/Juwon1405/GitNote/blob/main/Resources/[Cheatsheet]%20mft-timestomp-detection.md
"""

import csv
import sys
import json
import argparse
from datetime import datetime, timedelta

EXECUTABLE_EXTS = {
    '.exe', '.dll', '.sys', '.scr', '.com', '.cpl',
    '.ps1', '.psm1', '.bat', '.cmd', '.vbs', '.js',
    '.lnk', '.hta', '.msi', '.jar',
}


def parse_ts(s):
    """Parse MFTECmd timestamp string. Returns None if empty/invalid."""
    if not s or s.strip() == '':
        return None
    # MFTECmd typically uses: 2026-04-22 03:14:17.1234567 +00:00
    # Trim sub-second precision and timezone
    s = s.split('.')[0].split('+')[0].strip()
    try:
        return datetime.strptime(s, '%Y-%m-%d %H:%M:%S')
    except ValueError:
        try:
            return datetime.strptime(s, '%Y-%m-%dT%H:%M:%S')
        except ValueError:
            return None


def is_executable(path):
    """Check if path looks like an executable file."""
    if not path:
        return False
    lower = path.lower()
    for ext in EXECUTABLE_EXTS:
        if lower.endswith(ext):
            return True
    return False


def classify_severity(delta_seconds, exec_flag):
    """
    Classify severity:
      - executable + delta > 1h    → critical
      - executable + delta > 1s    → high
      - non-exec    + delta > 1h   → high
      - non-exec    + delta > 1s   → medium
      - delta < 1s                 → ignored (clock resolution noise)
    """
    if delta_seconds < 1:
        return None
    if exec_flag:
        return 'critical' if delta_seconds > 3600 else 'high'
    else:
        return 'high' if delta_seconds > 3600 else 'medium'


def detect_timestomp(row, tolerance=1):
    """Yield findings for one MFT row."""
    path = row.get('FullPath') or row.get('Filename') or '<unknown>'
    exec_flag = is_executable(path)

    si_created = parse_ts(row.get('Created0x10', ''))
    fn_created = parse_ts(row.get('Created0x30', ''))
    si_modified = parse_ts(row.get('LastModified0x10', ''))
    fn_modified = parse_ts(row.get('LastModified0x30', ''))

    findings = []

    # Pattern 1: $SI.created < $FN.created (created-time timestomp)
    if si_created and fn_created:
        delta = (fn_created - si_created).total_seconds()
        if delta > tolerance:
            sev = classify_severity(delta, exec_flag)
            if sev:
                findings.append({
                    'pattern': 'SI_CREATED_PREDATES_FN_CREATED',
                    'path': path,
                    'si_time': si_created.isoformat(),
                    'fn_time': fn_created.isoformat(),
                    'delta_seconds': int(delta),
                    'delta_human': format_delta(delta),
                    'severity': sev,
                    'is_executable': exec_flag,
                    'mitre': 'T1070.006',
                })

    # Pattern 2: $SI.modified < $FN.modified
    if si_modified and fn_modified:
        delta = (fn_modified - si_modified).total_seconds()
        if delta > tolerance:
            sev = classify_severity(delta, exec_flag)
            if sev:
                findings.append({
                    'pattern': 'SI_MODIFIED_PREDATES_FN_MODIFIED',
                    'path': path,
                    'si_time': si_modified.isoformat(),
                    'fn_time': fn_modified.isoformat(),
                    'delta_seconds': int(delta),
                    'delta_human': format_delta(delta),
                    'severity': sev,
                    'is_executable': exec_flag,
                    'mitre': 'T1070.006',
                })

    # Pattern 3: $SI.modified < $FN.created (logically impossible without timestomp)
    if si_modified and fn_created:
        delta = (fn_created - si_modified).total_seconds()
        if delta > tolerance:
            findings.append({
                'pattern': 'SI_MODIFIED_BEFORE_FN_CREATED_IMPOSSIBLE',
                'path': path,
                'si_time': si_modified.isoformat(),
                'fn_time': fn_created.isoformat(),
                'delta_seconds': int(delta),
                'delta_human': format_delta(delta),
                'severity': 'critical',  # always critical — logical impossibility
                'is_executable': exec_flag,
                'mitre': 'T1070.006',
                'note': 'A file cannot be modified before it was created — definite timestomp',
            })

    return findings


def format_delta(seconds):
    """Human-readable time delta."""
    if seconds < 60:
        return f"{int(seconds)}s"
    elif seconds < 3600:
        return f"{int(seconds/60)}m"
    elif seconds < 86400:
        return f"{int(seconds/3600)}h"
    elif seconds < 86400 * 365:
        return f"{int(seconds/86400)}d"
    else:
        return f"{int(seconds/86400/365)}y"


def main():
    p = argparse.ArgumentParser(description='Detect MFT timestomp ($SI < $FN)')
    p.add_argument('csv_file', help='MFTECmd CSV export')
    p.add_argument('--tolerance', type=int, default=1,
                   help='Tolerance in seconds (default: 1)')
    p.add_argument('--executables-only', action='store_true',
                   help='Only report executable file timestomps')
    p.add_argument('--json', action='store_true', help='Output JSON')
    p.add_argument('--severity', choices=['low', 'medium', 'high', 'critical'],
                   help='Minimum severity')
    args = p.parse_args()

    sev_rank = {'low': 0, 'medium': 1, 'high': 2, 'critical': 3}
    min_sev = sev_rank.get(args.severity, 0)

    all_findings = []
    total_rows = 0

    with open(args.csv_file, 'r', encoding='utf-8', errors='replace') as f:
        reader = csv.DictReader(f)
        for row in reader:
            total_rows += 1
            for finding in detect_timestomp(row, args.tolerance):
                if args.executables_only and not finding['is_executable']:
                    continue
                if sev_rank.get(finding['severity'], 0) < min_sev:
                    continue
                all_findings.append(finding)

    # Output
    if args.json:
        print(json.dumps({
            'tool': 'mft_timestomp_detector',
            'csv': args.csv_file,
            'rows_scanned': total_rows,
            'findings_count': len(all_findings),
            'findings': all_findings,
        }, indent=2))
    else:
        print(f"# mft_timestomp_detector — analyzed {total_rows} MFT rows")
        print(f"# Findings: {len(all_findings)} (tolerance={args.tolerance}s, "
              f"min_sev={args.severity or 'low'}, exec_only={args.executables_only})")
        print()

        # Sort: critical first, then by delta descending
        all_findings.sort(key=lambda x: (-sev_rank[x['severity']], -x['delta_seconds']))

        print(f"{'SEVERITY':10s}  {'EXEC?':6s}  {'DELTA':10s}  {'PATTERN':40s}  PATH")
        print('-' * 140)
        for f in all_findings:
            exec_mark = 'YES' if f['is_executable'] else '-'
            print(f"{f['severity']:10s}  {exec_mark:6s}  {f['delta_human']:10s}  "
                  f"{f['pattern']:40s}  {f['path'][:80]}")

        print()
        print(f"# Summary: critical={sum(1 for f in all_findings if f['severity']=='critical')}  "
              f"high={sum(1 for f in all_findings if f['severity']=='high')}  "
              f"medium={sum(1 for f in all_findings if f['severity']=='medium')}")


if __name__ == '__main__':
    main()
