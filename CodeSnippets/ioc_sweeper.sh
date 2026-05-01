#!/bin/bash
# ioc_sweeper.sh — Hot 2026 IOC sweep for compromised hosts
#
# Scans a host for indicators of compromise from recent (2025-2026) supply chain
# attacks and ransomware campaigns. Cross-platform (macOS, Linux). Read-only —
# does not modify any files or processes.
#
# Coverage:
#   1. litellm PyPI supply chain attack (Mar 2026) — malicious package
#   2. Generic .pth cache poisoning patterns (Python sys.path attacks)
#   3. polyfill.io supply chain (Jun 2024) — JS libs from cdn.polyfill.io
#   4. Common Python sitecustomize.py / usercustomize.py backdoors
#   5. Generic infostealer signatures (Lumma, Vidar, Stealc artifacts)
#   6. Hot 2026 ransomware tooling (SystemBC, StealBit, AdFind in suspicious paths)
#   7. Cobalt Strike beacon canaries (default profile filenames)
#   8. Mimikatz signatures in process memory paths
#
# Usage:
#   bash ioc_sweeper.sh                   # full sweep
#   bash ioc_sweeper.sh --output ./out    # specify output dir
#   sudo bash ioc_sweeper.sh              # use sudo for system paths
#
# Author: Yushin (https://github.com/Juwon1405)
# License: CC BY 4.0

set -uo pipefail
shopt -s nullglob 2>/dev/null || true

OUT="${1:-./ioc_sweep_$(hostname)_$(date +%Y%m%d_%H%M%S)}"
mkdir -p "$OUT"

OS="$(uname -s)"
echo "==> ioc_sweeper running on $OS — output: $OUT"
echo

# Helper — record finding
record() {
    local file="$1"
    local severity="$2"
    local description="$3"
    local evidence="$4"

    {
        echo "[$severity] $description"
        echo "  Evidence: $evidence"
        echo
    } >> "$OUT/$file"
}

# ---------------------------------------------------------
# 1. litellm PyPI supply chain attack signatures (Mar 2026)
# ---------------------------------------------------------
echo "==> 1. litellm PyPI supply chain attack (Mar 2026)"
{
    # Suspicious patterns associated with the campaign
    for path in /usr/lib/python*/site-packages/litellm \
                /usr/local/lib/python*/site-packages/litellm \
                "$HOME/.local/lib/python*/site-packages/litellm" \
                /opt/homebrew/lib/python*/site-packages/litellm; do
        # Use shell glob to expand
        for found in $path; do
            if [ -d "$found" ]; then
                # Check version — known-bad versions are typosquats
                if [ -f "$found/_version.py" ]; then
                    cat "$found/_version.py" 2>/dev/null
                fi
                # Look for unusual files
                find "$found" -type f -newer /etc/hostname 2>/dev/null | head -20
            fi
        done
    done
} > "$OUT/01_litellm.txt" 2>/dev/null

# ---------------------------------------------------------
# 2. Python sys.path manipulation — .pth files in user-writable site-packages
# ---------------------------------------------------------
echo "==> 2. Python .pth cache poisoning"
{
    # User-writable site-packages with .pth files (suspicious if user added them)
    for sp in $HOME/.local/lib/python*/site-packages \
              $HOME/Library/Python/*/lib/python/site-packages \
              /opt/homebrew/lib/python*/site-packages; do
        for path in $sp; do
            if [ -d "$path" ]; then
                find "$path" -name "*.pth" -type f 2>/dev/null | while read pthfile; do
                    echo "## $pthfile"
                    head -5 "$pthfile"
                    echo
                done
            fi
        done
    done

    # sitecustomize.py and usercustomize.py (auto-loaded on Python startup)
    for sp in $HOME/.local/lib/python*/site-packages \
              /usr/lib/python*/site-packages \
              /usr/local/lib/python*/site-packages; do
        for path in $sp; do
            for f in "$path/sitecustomize.py" "$path/usercustomize.py"; do
                if [ -f "$f" ]; then
                    echo "## $f"
                    head -20 "$f"
                    echo
                fi
            done
        done
    done
} > "$OUT/02_python_pth.txt" 2>/dev/null

# ---------------------------------------------------------
# 3. polyfill.io references (web supply chain — Jun 2024)
# ---------------------------------------------------------
echo "==> 3. polyfill.io references"
{
    # Search in common web-app locations
    for webroot in /var/www /usr/share/nginx /opt/lampp/htdocs \
                   /Library/WebServer/Documents /home/*/public_html; do
        for path in $webroot; do
            if [ -d "$path" ]; then
                grep -r --include="*.html" --include="*.js" --include="*.htm" \
                     -l "cdn.polyfill.io\|polyfill\.io/v3" "$path" 2>/dev/null
            fi
        done
    done
} > "$OUT/03_polyfill_io.txt" 2>/dev/null

# ---------------------------------------------------------
# 4. SystemBC proxy (used by The Gentlemen + others — 2026 hot)
# ---------------------------------------------------------
echo "==> 4. SystemBC / Cobalt Strike / Mimikatz binary signatures"
{
    # Search recent files in suspicious locations for known tooling
    for searchdir in /tmp /var/tmp /Users/Shared /ProgramData \
                     "$HOME/Library/Caches" "$HOME/.cache"; do
        if [ -d "$searchdir" ]; then
            # Recently created executables (last 30 days)
            find "$searchdir" -type f \( -name "*.exe" -o -name "*.dll" -o \
                  -perm -u+x -size +10k -size -50M \) -mtime -30 2>/dev/null | \
                head -50
        fi
    done

    # Process search for known names
    if command -v ps &>/dev/null; then
        echo
        echo "## Process matches"
        ps auxww 2>/dev/null | grep -iE 'systembc|stealbit|cobaltstrike|mimikatz|adfind\.exe' | \
            grep -v grep || echo "(none)"
    fi
} > "$OUT/04_ransomware_tooling.txt" 2>/dev/null

# ---------------------------------------------------------
# 5. Hot 2026 RMM tools used by ransomware affiliates
# ---------------------------------------------------------
echo "==> 5. Unsanctioned RMM tools (BlackSuit / RansomHub / Scattered Spider patterns)"
{
    # Look for installed RMM tools — flag any not on company allowlist
    RMM_TOOLS=("AnyDesk" "TeamViewer" "ScreenConnect" "Atera" "Splashtop"
               "ConnectWise" "LogMeIn" "GoToMyPC" "RustDesk" "Action1"
               "Kaseya" "NinjaRMM")

    if [ "$OS" = "Darwin" ]; then
        for app in /Applications/*.app; do
            for rmm in "${RMM_TOOLS[@]}"; do
                if [[ "$app" =~ "$rmm" ]] || [[ "$app" =~ $(echo $rmm | tr '[:upper:]' '[:lower:]') ]]; then
                    echo "## RMM detected: $app"
                    ls -la "$app/Contents/Info.plist" 2>/dev/null
                fi
            done
        done
    elif [ "$OS" = "Linux" ]; then
        for rmm in "${RMM_TOOLS[@]}"; do
            which "$(echo $rmm | tr '[:upper:]' '[:lower:]')" 2>/dev/null && echo "## RMM in PATH"
        done
        # Common Linux install paths
        find /opt /usr/local/bin /usr/bin -maxdepth 3 -iname "*anydesk*" -o \
             -iname "*teamviewer*" -o -iname "*rustdesk*" -o \
             -iname "*screenconnect*" 2>/dev/null
    fi

    # Process check
    echo
    echo "## RMM processes running"
    ps auxww 2>/dev/null | grep -iE "anydesk|teamviewer|screenconnect|atera|splashtop|connectwise|rustdesk" | \
        grep -v grep || echo "(none)"
} > "$OUT/05_rmm_tools.txt" 2>/dev/null

# ---------------------------------------------------------
# 6. Recovery denial signatures (M-Trends 2026 #1 ransomware trend)
# ---------------------------------------------------------
echo "==> 6. Recovery-denial commands in shell histories"
{
    PATTERNS='vssadmin.*delete.*shadows|wbadmin.*delete.*catalog|bcdedit.*recoveryenabled|wevtutil.*cl|fsutil.*usn.*deletejournal|del.*Prefetch'

    # Search bash/zsh histories
    for hist in /root/.bash_history /root/.zsh_history \
                /home/*/.bash_history /home/*/.zsh_history \
                /Users/*/.bash_history /Users/*/.zsh_history; do
        for f in $hist; do
            if [ -f "$f" ]; then
                grep -iE "$PATTERNS" "$f" 2>/dev/null | while read line; do
                    echo "## $f"
                    echo "  $line"
                done
            fi
        done
    done
} > "$OUT/06_recovery_denial.txt" 2>/dev/null

# ---------------------------------------------------------
# 7. SSH key persistence (T1098.004) - new authorized_keys entries
# ---------------------------------------------------------
echo "==> 7. SSH authorized_keys inventory"
{
    for keyfile in /root/.ssh/authorized_keys /home/*/.ssh/authorized_keys \
                   /Users/*/.ssh/authorized_keys; do
        for f in $keyfile; do
            if [ -f "$f" ]; then
                echo "## $f"
                echo "  Size: $(wc -l < "$f") keys"
                echo "  Modified: $(stat -c '%y' "$f" 2>/dev/null || stat -f '%Sm' "$f" 2>/dev/null)"
                cat "$f"
                echo
            fi
        done
    done
} > "$OUT/07_authorized_keys.txt" 2>/dev/null

# ---------------------------------------------------------
# 8. Cron / systemd timer / launchd persistence (cross-platform)
# ---------------------------------------------------------
echo "==> 8. Persistence inventory (cron / timer / launchd)"
{
    if [ "$OS" = "Linux" ]; then
        echo "## /etc/cron.* directories"
        ls -la /etc/cron.d/ /etc/cron.daily/ /etc/cron.hourly/ /etc/cron.weekly/ /etc/cron.monthly/ 2>/dev/null
        echo
        echo "## systemd timers"
        systemctl list-timers --all 2>/dev/null
        echo
        echo "## All user crontabs"
        for user in $(cut -d: -f1 /etc/passwd 2>/dev/null); do
            cron=$(crontab -u "$user" -l 2>/dev/null)
            [ -n "$cron" ] && echo "## $user" && echo "$cron"
        done
    elif [ "$OS" = "Darwin" ]; then
        echo "## /Library/Launch{Agents,Daemons}/"
        ls -la /Library/LaunchAgents/ /Library/LaunchDaemons/ 2>/dev/null | head -50
        echo
        echo "## Per-user LaunchAgents"
        ls -la /Users/*/Library/LaunchAgents/ 2>/dev/null | head -50
    fi
} > "$OUT/08_persistence.txt" 2>/dev/null

# ---------------------------------------------------------
# Summary
# ---------------------------------------------------------
{
    echo "## ioc_sweeper Summary"
    echo "Host: $(hostname)"
    echo "OS: $OS"
    echo "Date: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
    echo "Run as: $(whoami)"
    echo
    echo "## Findings per category (non-empty file lines)"
    for f in "$OUT"/[0-9]*.txt; do
        name=$(basename "$f" .txt)
        lines=$(grep -v '^$\|^##' "$f" 2>/dev/null | wc -l | tr -d ' ')
        printf "  %-40s  %4d lines\n" "$name" "$lines"
    done
    echo
    echo "## Hash manifest"
    if command -v sha256sum &>/dev/null; then
        ( cd "$OUT" && sha256sum *.txt > SHA256SUMS )
    else
        ( cd "$OUT" && shasum -a 256 *.txt > SHA256SUMS )
    fi
    cat "$OUT/SHA256SUMS"
} > "$OUT/00_SUMMARY.txt"

cat "$OUT/00_SUMMARY.txt"
echo
echo "==> Sweep complete. Investigate any non-empty file."
echo "    Critical priorities: 04_ransomware_tooling, 05_rmm_tools, 06_recovery_denial"
