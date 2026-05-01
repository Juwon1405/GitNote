#!/usr/bin/env python3
"""
browser_history_carve.py — Unified browser history dump for DFIR

Carves browsing history from Chrome, Edge, Firefox, and Safari into a
single normalized CSV. Read-only; copies databases to a working directory
before reading to preserve original timestamps and avoid lock issues.

Supports:
  - Google Chrome (all profiles in default location)
  - Microsoft Edge (Chromium, all profiles)
  - Mozilla Firefox (all profiles)
  - Safari (macOS only)

Output is normalized to:
    timestamp_utc, browser, profile, url, title, visit_count

Usage:
    python3 browser_history_carve.py                    # auto-detect, all browsers
    python3 browser_history_carve.py --output hist.csv
    python3 browser_history_carve.py --browser chrome --user alice
    python3 browser_history_carve.py --json

On macOS: run with sudo for system-wide enumeration.
On Windows: run as the target user, OR mount the user profile and use --root.

Author: Yushin (https://github.com/Juwon1405)
License: CC BY 4.0
"""

import os
import sys
import csv
import json
import shutil
import sqlite3
import tempfile
import argparse
import platform
from datetime import datetime, timezone, timedelta
from pathlib import Path

# Chromium epoch (Jan 1 1601) → Unix epoch
CHROMIUM_EPOCH_OFFSET = 11644473600  # seconds

def chromium_ts_to_iso(microseconds):
    """Chrome/Edge use microseconds since 1601-01-01 UTC."""
    if not microseconds or microseconds == 0:
        return ''
    seconds = microseconds / 1_000_000 - CHROMIUM_EPOCH_OFFSET
    try:
        return datetime.fromtimestamp(seconds, tz=timezone.utc).isoformat()
    except (OSError, OverflowError, ValueError):
        return ''

def firefox_ts_to_iso(microseconds):
    """Firefox uses microseconds since Unix epoch."""
    if not microseconds or microseconds == 0:
        return ''
    seconds = microseconds / 1_000_000
    try:
        return datetime.fromtimestamp(seconds, tz=timezone.utc).isoformat()
    except (OSError, OverflowError, ValueError):
        return ''

def safari_ts_to_iso(seconds):
    """Safari uses seconds since 2001-01-01 UTC (Cocoa epoch)."""
    if not seconds:
        return ''
    cocoa_offset = 978307200  # 2001-01-01 - 1970-01-01
    try:
        return datetime.fromtimestamp(seconds + cocoa_offset, tz=timezone.utc).isoformat()
    except (OSError, OverflowError, ValueError):
        return ''


def safe_query(db_path, query):
    """
    Copy db to temp (handles WAL/SHM if present), open read-only, run query.
    Returns list of rows or empty list on error.
    """
    if not os.path.isfile(db_path):
        return []

    with tempfile.TemporaryDirectory() as tmp:
        target = os.path.join(tmp, os.path.basename(db_path))
        try:
            shutil.copy2(db_path, target)
            # Copy WAL/SHM sidecars if present
            for ext in ('-wal', '-shm', '.wal', '.shm'):
                sidecar = db_path + ext
                if os.path.isfile(sidecar):
                    shutil.copy2(sidecar, target + ext)
        except (PermissionError, FileNotFoundError):
            return []

        try:
            conn = sqlite3.connect(f'file:{target}?mode=ro', uri=True, timeout=10)
            conn.row_factory = sqlite3.Row
            cur = conn.cursor()
            cur.execute(query)
            rows = cur.fetchall()
            conn.close()
            return [dict(r) for r in rows]
        except sqlite3.Error as e:
            print(f"  ! SQL error reading {db_path}: {e}", file=sys.stderr)
            return []


def find_chromium_profiles(base_path):
    """Find all profile dirs under base_path (Default, Profile 1, Profile 2, etc.)."""
    if not os.path.isdir(base_path):
        return []
    profiles = []
    for entry in os.listdir(base_path):
        full = os.path.join(base_path, entry)
        if os.path.isdir(full) and (entry == 'Default' or entry.startswith('Profile ')):
            history = os.path.join(full, 'History')
            if os.path.isfile(history):
                profiles.append((entry, history))
    return profiles


def parse_chromium(label, base_path):
    """Parse Chrome / Edge histories. Returns list of normalized dicts."""
    rows = []
    for profile, db in find_chromium_profiles(base_path):
        query = """
            SELECT urls.url, urls.title, urls.visit_count, urls.last_visit_time
            FROM urls
            ORDER BY urls.last_visit_time DESC
        """
        for r in safe_query(db, query):
            rows.append({
                'timestamp_utc': chromium_ts_to_iso(r.get('last_visit_time')),
                'browser': label,
                'profile': profile,
                'url': r.get('url') or '',
                'title': r.get('title') or '',
                'visit_count': r.get('visit_count', 0),
            })
    return rows


def parse_firefox(profiles_dir):
    """Parse Firefox places.sqlite from all profiles."""
    rows = []
    if not os.path.isdir(profiles_dir):
        return rows
    for entry in os.listdir(profiles_dir):
        prof_dir = os.path.join(profiles_dir, entry)
        if not os.path.isdir(prof_dir):
            continue
        db = os.path.join(prof_dir, 'places.sqlite')
        if not os.path.isfile(db):
            continue
        query = """
            SELECT moz_places.url, moz_places.title, moz_places.visit_count,
                   moz_historyvisits.visit_date
            FROM moz_places
            JOIN moz_historyvisits ON moz_places.id = moz_historyvisits.place_id
            ORDER BY moz_historyvisits.visit_date DESC
        """
        for r in safe_query(db, query):
            rows.append({
                'timestamp_utc': firefox_ts_to_iso(r.get('visit_date')),
                'browser': 'Firefox',
                'profile': entry,
                'url': r.get('url') or '',
                'title': r.get('title') or '',
                'visit_count': r.get('visit_count', 0),
            })
    return rows


def parse_safari(history_db):
    """Parse Safari History.db (macOS)."""
    rows = []
    query = """
        SELECT history_items.url, history_visits.title,
               history_items.visit_count, history_visits.visit_time
        FROM history_items
        JOIN history_visits ON history_items.id = history_visits.history_item
        ORDER BY history_visits.visit_time DESC
    """
    for r in safe_query(history_db, query):
        rows.append({
            'timestamp_utc': safari_ts_to_iso(r.get('visit_time')),
            'browser': 'Safari',
            'profile': 'Default',
            'url': r.get('url') or '',
            'title': r.get('title') or '',
            'visit_count': r.get('visit_count', 0),
        })
    return rows


def detect_paths(user_home=None):
    """Return dict of {browser: path} for the given user."""
    if user_home is None:
        user_home = os.path.expanduser('~')

    sys_name = platform.system()
    paths = {}

    if sys_name == 'Darwin':
        paths['Chrome']   = f'{user_home}/Library/Application Support/Google/Chrome'
        paths['Edge']     = f'{user_home}/Library/Application Support/Microsoft Edge'
        paths['Firefox']  = f'{user_home}/Library/Application Support/Firefox/Profiles'
        paths['Safari']   = f'{user_home}/Library/Safari/History.db'
    elif sys_name == 'Linux':
        paths['Chrome']   = f'{user_home}/.config/google-chrome'
        paths['Edge']     = f'{user_home}/.config/microsoft-edge'
        paths['Firefox']  = f'{user_home}/.mozilla/firefox'
    elif sys_name == 'Windows':
        local = os.environ.get('LOCALAPPDATA', f'{user_home}\\AppData\\Local')
        roaming = os.environ.get('APPDATA', f'{user_home}\\AppData\\Roaming')
        paths['Chrome']   = f'{local}\\Google\\Chrome\\User Data'
        paths['Edge']     = f'{local}\\Microsoft\\Edge\\User Data'
        paths['Firefox']  = f'{roaming}\\Mozilla\\Firefox\\Profiles'

    return paths


def main():
    p = argparse.ArgumentParser(description='Multi-browser history carving for DFIR')
    p.add_argument('--output', '-o', default='browser_history.csv',
                   help='Output CSV file (default: browser_history.csv)')
    p.add_argument('--browser', choices=['chrome', 'edge', 'firefox', 'safari', 'all'],
                   default='all', help='Browser to dump (default: all)')
    p.add_argument('--root', help='User home dir (e.g. /Users/alice). Default: current user.')
    p.add_argument('--json', action='store_true', help='Output JSON instead of CSV')
    args = p.parse_args()

    paths = detect_paths(args.root)
    all_rows = []

    print(f"==> browser_history_carve — platform: {platform.system()}", file=sys.stderr)
    print(f"    User home: {args.root or os.path.expanduser('~')}", file=sys.stderr)
    print(file=sys.stderr)

    if args.browser in ('chrome', 'all') and 'Chrome' in paths:
        print(f"  [chrome]  parsing {paths['Chrome']}", file=sys.stderr)
        all_rows.extend(parse_chromium('Chrome', paths['Chrome']))

    if args.browser in ('edge', 'all') and 'Edge' in paths:
        print(f"  [edge]    parsing {paths['Edge']}", file=sys.stderr)
        all_rows.extend(parse_chromium('Edge', paths['Edge']))

    if args.browser in ('firefox', 'all') and 'Firefox' in paths:
        print(f"  [firefox] parsing {paths['Firefox']}", file=sys.stderr)
        all_rows.extend(parse_firefox(paths['Firefox']))

    if args.browser in ('safari', 'all') and 'Safari' in paths:
        print(f"  [safari]  parsing {paths['Safari']}", file=sys.stderr)
        all_rows.extend(parse_safari(paths['Safari']))

    print(file=sys.stderr)
    print(f"==> Total rows: {len(all_rows)}", file=sys.stderr)

    # Sort by timestamp descending (most recent first)
    all_rows.sort(key=lambda r: r.get('timestamp_utc', ''), reverse=True)

    if args.json:
        with open(args.output.replace('.csv', '.json'), 'w') as f:
            json.dump(all_rows, f, indent=2)
        print(f"==> Wrote: {args.output.replace('.csv', '.json')}", file=sys.stderr)
    else:
        with open(args.output, 'w', newline='', encoding='utf-8') as f:
            if not all_rows:
                f.write('timestamp_utc,browser,profile,url,title,visit_count\n')
            else:
                writer = csv.DictWriter(f, fieldnames=['timestamp_utc', 'browser', 'profile',
                                                        'url', 'title', 'visit_count'])
                writer.writeheader()
                writer.writerows(all_rows)
        print(f"==> Wrote: {args.output}", file=sys.stderr)


if __name__ == '__main__':
    main()
