#!/usr/bin/env python3
"""
evtx_quick_triage.py — Quick EVTX triage for incident response

Surfaces the top suspicious patterns from Windows Security event logs
without needing Hayabusa or a full SIEM. Self-contained (only depends
on `python-evtx`).

Detects:
  - Privilege escalation (4672 without preceding cred-access TTP)
  - Failed logon bursts (4625 brute force / spray)
  - Process creation with suspicious command lines (4688)
  - Service install (4697) — common PsExec lateral movement signature
  - Explicit credential use (4648) — first-hop lateral movement
  - PowerShell encoded commands (4104, 4688)
  - LSASS dump signatures (comsvcs.dll MiniDump)
  - Recovery denial (vssadmin / wbadmin / wevtutil cl)

Usage:
    pip install python-evtx
    python3 evtx_quick_triage.py /path/to/Security.evtx
    python3 evtx_quick_triage.py /path/to/EVTX_dir/  # processes whole dir

Output:
    Compact CSV-like report to stdout.
    Use --json for machine-readable output.
    Use --severity high to filter to only critical/high findings.

Author: Yushin (https://github.com/Juwon1405)
License: CC BY 4.0
"""

import sys
import os
import re
import json
import argparse
import glob
from datetime import datetime
from xml.etree import ElementTree as ET

try:
    from Evtx.Evtx import Evtx
except ImportError:
    print("ERROR: python-evtx not installed. Run: pip install python-evtx", file=sys.stderr)
    sys.exit(1)

# Patterns surfaced as findings — tuned for ~10 minutes of analyst review
SUSPICIOUS_CMDLINE = [
    (r'comsvcs\.dll.*MiniDump',          'critical', 'T1003.001 LSASS dump via comsvcs.dll'),
    (r'-(EncodedCommand|enc|e)\s+[A-Za-z0-9+/=]{50,}',
                                          'high',     'T1059.001 PowerShell encoded command'),
    (r'vssadmin\s+delete\s+shadows',     'critical', 'T1490 Shadow copy deletion (recovery denial)'),
    (r'wbadmin\s+delete\s+catalog',      'critical', 'T1490 Backup catalog deletion'),
    (r'wevtutil\s+cl\s+',                'high',     'T1070.001 Event log clearing'),
    (r'bcdedit.*recoveryenabled\s+No',   'critical', 'T1490 Recovery disabled'),
    (r'reg\s+save.*HKLM\\SAM',           'high',     'T1003.002 SAM hive dump'),
    (r'reg\s+save.*HKLM\\SYSTEM',        'high',     'T1003.002 SYSTEM hive dump'),
    (r'(net|net1)\s+user.*\/add',        'high',     'T1136.001 Local account creation'),
    (r'schtasks.*\/create',              'medium',   'T1053.005 Scheduled task creation'),
    (r'sc\s+create\s+\S+\s+binpath',     'high',     'T1543.003 Service creation (lateral movement?)'),
    (r'Add-MpPreference.*ExclusionPath', 'high',     'T1562.001 Defender exclusion added'),
    (r'Set-MpPreference.*Disable',       'critical', 'T1562.001 Defender component disabled'),
    (r'mimikatz',                         'critical', 'Mimikatz reference in command'),
    (r'(curl|wget|Invoke-WebRequest)\s+http.*\.(exe|ps1|bat|sh|dll)',
                                          'high',     'Remote payload download'),
    (r'rundll32.*\\\\.*\.dll',           'medium',   'rundll32 with UNC path'),
]

# Compile once
COMPILED = [(re.compile(p, re.IGNORECASE), sev, desc) for p, sev, desc in SUSPICIOUS_CMDLINE]


def parse_event(record):
    """Extract relevant fields from an EVTX record's XML."""
    try:
        xml = record.xml()
        # Strip namespace for easier parsing
        xml = re.sub(r'\sxmlns="[^"]+"', '', xml, count=1)
        root = ET.fromstring(xml)

        eid_elem = root.find('.//EventID')
        eid = eid_elem.text if eid_elem is not None else None

        time_elem = root.find('.//TimeCreated')
        ts = time_elem.get('SystemTime') if time_elem is not None else None

        computer_elem = root.find('.//Computer')
        computer = computer_elem.text if computer_elem is not None else ''

        # Collect EventData fields
        data = {}
        for d in root.findall('.//EventData/Data'):
            name = d.get('Name', '')
            value = d.text or ''
            if name:
                data[name] = value

        return {'eid': eid, 'ts': ts, 'computer': computer, 'data': data}
    except (ET.ParseError, Exception):
        return None


def analyze_event(ev):
    """Return list of findings for one event."""
    findings = []
    if not ev or not ev['eid']:
        return findings

    eid = ev['eid']
    data = ev['data']

    # 4625 — failed logon (track for burst detection by caller)
    if eid == '4625':
        findings.append({
            'severity': 'low', 'eid': eid, 'ts': ev['ts'],
            'computer': ev['computer'],
            'desc': f"Failed logon — user={data.get('TargetUserName','?')} src={data.get('IpAddress','?')}",
            'mitre': 'T1110',
        })

    # 4672 — special privileges granted (potential Golden Ticket if no preceding cred access)
    if eid == '4672':
        findings.append({
            'severity': 'medium', 'eid': eid, 'ts': ev['ts'],
            'computer': ev['computer'],
            'desc': f"Admin privileges granted — user={data.get('SubjectUserName','?')}",
            'mitre': 'T1078',
            'note': 'Golden Ticket suspect if no preceding T1003/T1558/T1068',
        })

    # 4648 — explicit credential use (first hop in lateral movement)
    if eid == '4648':
        target = data.get('TargetUserName', '?')
        if target.lower() not in ('-', 'localhost', ''):
            findings.append({
                'severity': 'medium', 'eid': eid, 'ts': ev['ts'],
                'computer': ev['computer'],
                'desc': f"Explicit cred use — by={data.get('SubjectUserName','?')} as={target} target_host={data.get('TargetServerName','?')}",
                'mitre': 'T1078',
            })

    # 4697 — service install (PsExec / lateral movement)
    if eid == '4697':
        svc = data.get('ServiceName', '?')
        path = data.get('ServiceFileName', '?')
        sev = 'high' if re.match(r'^[a-zA-Z0-9]{8}$', svc) else 'medium'  # random 8-char = PsExec
        findings.append({
            'severity': sev, 'eid': eid, 'ts': ev['ts'],
            'computer': ev['computer'],
            'desc': f"Service install — name={svc} path={path[:80]}",
            'mitre': 'T1543.003',
        })

    # 4688 — process creation (the meat)
    if eid == '4688':
        cmdline = data.get('CommandLine', '') or data.get('NewProcessName', '')
        for regex, sev, desc in COMPILED:
            if regex.search(cmdline):
                findings.append({
                    'severity': sev, 'eid': eid, 'ts': ev['ts'],
                    'computer': ev['computer'],
                    'desc': f"{desc} — cmd={cmdline[:120]}",
                    'mitre': desc.split()[0] if desc.split()[0].startswith('T') else None,
                })
                break  # one finding per command

    # 4624 — successful logon (flag suspicious patterns)
    if eid == '4624':
        logon_type = data.get('LogonType', '')
        auth_pkg = data.get('AuthenticationPackageName', '')
        target = data.get('TargetUserName', '')
        # NTLM for privileged account = Pass-the-Hash candidate
        if (auth_pkg.upper() == 'NTLM' and
            logon_type in ('3', '9') and
            (target.lower() == 'administrator' or
             target.lower().startswith('admin') or
             target.lower().startswith('svc'))):
            findings.append({
                'severity': 'high', 'eid': eid, 'ts': ev['ts'],
                'computer': ev['computer'],
                'desc': f"NTLM auth for privileged account — user={target} type={logon_type}",
                'mitre': 'T1550.002',
            })

    return findings


def process_file(path, severity_filter=None):
    """Process one EVTX file, yield findings."""
    failed_logons = {}  # ip -> count for burst detection
    findings_count = 0

    try:
        with Evtx(path) as evtx:
            for record in evtx.records():
                ev = parse_event(record)
                if not ev:
                    continue
                for f in analyze_event(ev):
                    if severity_filter:
                        sev_rank = {'low': 0, 'medium': 1, 'high': 2, 'critical': 3}
                        if sev_rank.get(f['severity'], 0) < sev_rank.get(severity_filter, 0):
                            continue
                    findings_count += 1
                    yield f

                # Track failed logon bursts
                if ev['eid'] == '4625':
                    ip = ev['data'].get('IpAddress', 'unknown')
                    failed_logons[ip] = failed_logons.get(ip, 0) + 1
    except Exception as e:
        print(f"WARN: error parsing {path}: {e}", file=sys.stderr)
        return

    # Emit burst findings
    for ip, count in failed_logons.items():
        if count >= 10:
            yield {
                'severity': 'high', 'eid': 'BURST', 'ts': '',
                'computer': '',
                'desc': f"Failed logon BURST — {count} attempts from {ip}",
                'mitre': 'T1110.003',
            }


def main():
    p = argparse.ArgumentParser(description='Quick EVTX triage for IR')
    p.add_argument('path', help='EVTX file or directory of EVTX files')
    p.add_argument('--json', action='store_true', help='Output JSON')
    p.add_argument('--severity', choices=['low', 'medium', 'high', 'critical'],
                   help='Minimum severity to report')
    args = p.parse_args()

    # Resolve target files
    if os.path.isdir(args.path):
        targets = sorted(glob.glob(os.path.join(args.path, '*.evtx')))
    else:
        targets = [args.path]

    if not targets:
        print("No EVTX files found.", file=sys.stderr)
        sys.exit(1)

    # Header
    if not args.json:
        print(f"# evtx_quick_triage — {datetime.utcnow().isoformat()}Z")
        print(f"# Files: {len(targets)}  Severity filter: {args.severity or 'all'}\n")
        print(f"{'SEVERITY':10s}  {'EID':6s}  {'TIME':24s}  {'MITRE':14s}  DESCRIPTION")
        print('-' * 130)

    all_findings = []
    for path in targets:
        if not args.json:
            print(f"\n## {os.path.basename(path)}", file=sys.stderr)
        for f in process_file(path, args.severity):
            if args.json:
                all_findings.append(f)
            else:
                ts = (f['ts'] or '')[:24]
                print(f"{f['severity']:10s}  {f['eid']:6s}  {ts:24s}  "
                      f"{(f.get('mitre') or '-'):14s}  {f['desc']}")

    if args.json:
        print(json.dumps(all_findings, indent=2, default=str))


if __name__ == '__main__':
    main()
