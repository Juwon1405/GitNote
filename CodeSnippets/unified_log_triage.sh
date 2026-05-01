#!/bin/bash
# unified_log_triage.sh — macOS Unified Log triage with security predicates
#
# Runs the 12 highest-yield Unified Log queries from the macos-unified-log-triage
# cheatsheet and saves output to a triage directory. Designed to run in
# ~2 minutes on a live host with default 7d retention.
#
# Usage:
#   sudo bash unified_log_triage.sh [output_dir] [time_window]
#   sudo bash unified_log_triage.sh /tmp/triage 24h
#   sudo bash unified_log_triage.sh /tmp/triage 7d   # default
#
# Author: Yushin (https://github.com/Juwon1405)
# License: CC BY 4.0
# Reference: https://github.com/Juwon1405/GitNote/blob/main/Resources/[Cheatsheet]%20macos-unified-log-triage.md

set -uo pipefail

OUT="${1:-./unified_log_triage_$(hostname)_$(date +%Y%m%d_%H%M%S)}"
WINDOW="${2:-7d}"

mkdir -p "$OUT"
echo "==> Unified log triage — output: $OUT  window: $WINDOW"

# Helper — run log show with a predicate, save to file
qlog() {
    local outfile="$1"
    local predicate="$2"
    local note="$3"

    echo "  [$(date +%H:%M:%S)] $note"
    echo "## Predicate: $predicate" > "$OUT/$outfile"
    echo "## Window: $WINDOW" >> "$OUT/$outfile"
    echo "## Run: $(date)" >> "$OUT/$outfile"
    echo >> "$OUT/$outfile"
    log show --last "$WINDOW" --predicate "$predicate" --style compact 2>/dev/null >> "$OUT/$outfile" || true

    local lines=$(wc -l < "$OUT/$outfile" | tr -d ' ')
    echo "       → $lines lines"
}

# 1. SSH activity
qlog "01_ssh.txt" \
     'process == "sshd" AND (eventMessage CONTAINS "Accepted" OR eventMessage CONTAINS "Failed" OR eventMessage CONTAINS "Invalid")' \
     'SSH authentication events'

# 2. sudo / privilege escalation
qlog "02_sudo.txt" \
     'process == "sudo" AND eventMessage CONTAINS "TTY="' \
     'sudo invocations'

# 3. TCC modifications
qlog "03_tcc.txt" \
     'subsystem == "com.apple.TCC"' \
     'TCC privacy database events'

# 4. launchd jobs
qlog "04_launchd.txt" \
     'process == "launchd" AND (eventMessage CONTAINS "registering" OR eventMessage CONTAINS "loaded" OR eventMessage CONTAINS "submitted")' \
     'launchd job activity'

# 5. Quarantine bypass
qlog "05_quarantine.txt" \
     'subsystem == "com.apple.LaunchServices" AND (eventMessage CONTAINS "quarantine" OR eventMessage CONTAINS "Gatekeeper")' \
     'Gatekeeper / quarantine activity'

# 6. XPC service registration
qlog "06_xpc.txt" \
     'subsystem == "com.apple.xpc.launchd" AND eventMessage CONTAINS "Service"' \
     'XPC service activity'

# 7. Network configuration
qlog "07_network.txt" \
     'subsystem == "com.apple.SystemConfiguration"' \
     'Network configuration changes'

# 8. XProtect / MRT
qlog "08_xprotect.txt" \
     'subsystem CONTAINS "com.apple.XProtect" OR subsystem CONTAINS "com.apple.MRT"' \
     'XProtect / MRT events'

# 9. Authentication failures
qlog "09_auth_failures.txt" \
     'eventMessage CONTAINS[c] "authentication failed" OR eventMessage CONTAINS[c] "auth failure" OR eventMessage CONTAINS[c] "login failed"' \
     'Authentication failures (all subsystems)'

# 10. Code signing failures
qlog "10_codesign.txt" \
     'subsystem == "com.apple.LaunchServices" AND eventMessage CONTAINS "code signing"' \
     'Code signing failures'

# 11. Endpoint Security Framework
qlog "11_esf.txt" \
     'subsystem == "com.apple.endpointsecurity"' \
     'Endpoint Security Framework events'

# 12. Last 5 minutes — alarm bell
qlog "12_recent_errors.txt" \
     '(eventMessage CONTAINS[c] "fail" OR eventMessage CONTAINS[c] "denied" OR eventMessage CONTAINS[c] "error") AND messageType == "Error"' \
     'Recent error / fail / denied events'

# ------------------------------------------------------------------
# Summary
# ------------------------------------------------------------------
{
  echo "## Unified Log Triage Summary"
  echo "Host: $(hostname)"
  echo "Date: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  echo "Window: $WINDOW"
  echo "Run as: $(whoami)"
  echo
  echo "## File summary (lines per output)"
  for f in "$OUT"/[0-9]*.txt; do
    name=$(basename "$f")
    # Subtract 4 header lines
    lines=$(($(wc -l < "$f" | tr -d ' ') - 4))
    [ "$lines" -lt 0 ] && lines=0
    printf "  %-30s  %6d events\n" "$name" "$lines"
  done
  echo
  echo "## Hash manifest"
  ( cd "$OUT" && shasum -a 256 *.txt > SHA256SUMS )
  cat "$OUT/SHA256SUMS"
} > "$OUT/00_SUMMARY.txt"

cat "$OUT/00_SUMMARY.txt"
echo
echo "==> Triage complete. Start review with 09_auth_failures.txt and 12_recent_errors.txt"
