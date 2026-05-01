#!/bin/bash
# auditd_lateral_movement.sh — Search auditd logs for lateral movement signatures
#
# Searches /var/log/audit/audit.log for the patterns commonly seen in
# Linux post-exploitation lateral movement:
#   - SSH key additions to authorized_keys (T1098.004)
#   - Reverse shell commands in execve syscalls
#   - Suspicious sudo escalations (sudo -i, sudo su, sudo bash)
#   - Network tunnels (socat, ssh -R, sshuttle)
#   - Wget/curl piping to shell (T1059.004)
#   - LD_PRELOAD environment manipulation (rootkit prep)
#
# Usage:
#   sudo bash auditd_lateral_movement.sh
#   sudo bash auditd_lateral_movement.sh /var/log/audit/audit.log.1
#   sudo bash auditd_lateral_movement.sh --since "2026-04-22 00:00:00"
#
# Author: Yushin (https://github.com/Juwon1405)
# License: CC BY 4.0
# Reference: https://github.com/Juwon1405/GitNote/blob/main/Resources/[Cheatsheet]%20linux-dfir-triage-2026.md

set -uo pipefail

# Default audit log
AUDIT_LOG="${1:-/var/log/audit/audit.log}"

if [ ! -r "$AUDIT_LOG" ]; then
    echo "ERROR: cannot read $AUDIT_LOG" >&2
    echo "  → Try with sudo, or specify path: $0 /path/to/audit.log" >&2
    exit 1
fi

if ! command -v ausearch &>/dev/null; then
    echo "ERROR: ausearch not found. Install audit package:" >&2
    echo "  Debian/Ubuntu: apt install auditd" >&2
    echo "  RHEL/CentOS:   yum install audit" >&2
    exit 1
fi

OUT="./auditd_lm_$(hostname)_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$OUT"

echo "==> auditd lateral-movement search → $OUT"
echo "    Log: $AUDIT_LOG"
echo

# Helper — search audit.log via ausearch + grep, save findings
search() {
    local label="$1"
    local pattern="$2"
    local note="$3"
    local mitre="$4"

    echo "  [search] $label ($mitre)"
    {
        echo "## $label"
        echo "## MITRE: $mitre"
        echo "## Note: $note"
        echo "## Pattern: $pattern"
        echo
        ausearch -if "$AUDIT_LOG" -ts recent -m EXECVE -i 2>/dev/null | \
            grep -iE "$pattern" || echo "(no matches)"
    } > "$OUT/${label}.txt"
}

# 1. SSH authorized_keys modifications (T1098.004)
echo "==> Phase 1: SSH key persistence"
{
    echo "## SSH authorized_keys modifications"
    echo "## MITRE: T1098.004"
    echo
    # Use auditd path watch results if rule exists
    ausearch -if "$AUDIT_LOG" -k root_ssh -i 2>/dev/null
    ausearch -if "$AUDIT_LOG" -k ssh_keys -i 2>/dev/null
    # Fallback — search any execve touching authorized_keys
    ausearch -if "$AUDIT_LOG" -ts recent -m EXECVE -i 2>/dev/null | \
        grep -iE 'authorized_keys' || echo "(no execve touched authorized_keys)"
} > "$OUT/01_ssh_keys.txt"

# 2. Reverse shell signatures
search "02_reverse_shells" \
    'bash -i.*/dev/tcp/|/dev/tcp/.*<&|exec.*[0-9]+.*<>/dev/tcp|nc.*-e.*(/bin/sh|/bin/bash)|python.*socket.*connect.*subprocess|perl.*Socket.*exec' \
    'Classic reverse-shell one-liners' \
    'T1059.004 / T1071.001'

# 3. Suspicious sudo
search "03_sudo_escalation" \
    'sudo (-i|-s|su |bash|/bin/sh|/bin/bash)' \
    'sudo to interactive root shell — potential escalation' \
    'T1548.003'

# 4. Network tunnels
search "04_tunnels" \
    'socat .*tcp-connect|socat .*tcp-listen|sshuttle|ssh.*-R [0-9]+|chisel' \
    'Reverse port forwarding / tunneling tools' \
    'T1572 / T1090'

# 5. Pipe-to-shell remote payload
search "05_pipe_to_shell" \
    '(curl|wget) .*\| ?(bash|sh|python|perl)|(curl|wget) -[a-z]*o ?- ?https?:.*\|' \
    'curl/wget piping to shell — remote payload execution' \
    'T1059.004 + T1105'

# 6. LD_PRELOAD manipulation
search "06_ld_preload" \
    'LD_PRELOAD=' \
    'LD_PRELOAD env var (rootkit / library hijacking)' \
    'T1574.006'

# 7. Persistence — cron and systemd
search "07_cron_systemd" \
    'crontab -e|crontab -l|systemctl (enable|start) .*\.(service|timer)|/etc/cron\.|/etc/systemd/system' \
    'Cron / systemd persistence operations' \
    'T1053.003 + T1543.002'

# 8. /etc/passwd or /etc/shadow modification
{
    echo "## /etc/passwd or /etc/shadow modifications"
    echo "## MITRE: T1136 + T1003.008"
    echo
    ausearch -if "$AUDIT_LOG" -k passwd_changes -i 2>/dev/null
    ausearch -if "$AUDIT_LOG" -k shadow_changes -i 2>/dev/null
    # If those keys aren't configured, fallback grep
    ausearch -if "$AUDIT_LOG" -ts recent -m EXECVE -i 2>/dev/null | \
        grep -iE '(useradd|usermod|passwd|chpasswd) ' || true
} > "$OUT/08_passwd_changes.txt"

# 9. History wipe attempts
search "09_history_wipe" \
    'history -c|HISTFILE=/dev/null|unset HISTFILE|cat /dev/null > .*history|rm .*\.bash_history|rm .*\.zsh_history' \
    'Bash/zsh history clearing — anti-forensics' \
    'T1070.003'

# 10. Defense evasion — disabling auditd or syslog
search "10_audit_disable" \
    '(systemctl (stop|disable) (auditd|rsyslog|systemd-journald))|service auditd stop|auditctl -e 0' \
    'Disabling logging services' \
    'T1562.001 + T1070.002'

# ------------------------------------------------------------------
# Summary
# ------------------------------------------------------------------
{
    echo "## auditd Lateral Movement Search Summary"
    echo "Host: $(hostname)"
    echo "Date: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
    echo "Audit log: $AUDIT_LOG"
    echo "Run as: $(whoami)"
    echo
    echo "## Findings per pattern"
    for f in "$OUT"/[0-9]*.txt; do
        name=$(basename "$f" .txt)
        # Count non-comment, non-empty lines
        hits=$(grep -c -v '^##\|^$\|(no matches)' "$f" 2>/dev/null || echo 0)
        printf "  %-30s  %6d hits\n" "$name" "$hits"
    done
    echo
    echo "## Hash manifest"
    ( cd "$OUT" && sha256sum *.txt > SHA256SUMS )
    cat "$OUT/SHA256SUMS"
} > "$OUT/00_SUMMARY.txt"

cat "$OUT/00_SUMMARY.txt"
echo
echo "==> Done. Investigate any file with > 0 hits."
echo "    Critical priorities: 01_ssh_keys, 02_reverse_shells, 06_ld_preload, 10_audit_disable"
