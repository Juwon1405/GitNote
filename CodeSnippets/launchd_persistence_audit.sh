#!/bin/bash
# launchd_persistence_audit.sh — macOS persistence inventory
#
# Enumerates all launchd persistence locations and surfaces the ones
# most likely to be attacker-installed:
#   - User-writable LaunchAgents with RunAtLoad=true
#   - Plists with command paths in /tmp, /private/tmp, ~/Library/Caches
#   - Plists owned by non-root in /Library/LaunchDaemons (suspicious)
#   - Plists not signed by Apple (when possible to determine)
#   - Recently created/modified plists
#
# Outputs a triage report you can review in 2-3 minutes.
#
# Usage:
#   sudo bash launchd_persistence_audit.sh             # full audit (sudo for system paths)
#   sudo bash launchd_persistence_audit.sh /tmp/out    # write to specific dir
#
# Author: Yushin (https://github.com/Juwon1405)
# License: CC BY 4.0
# Reference: https://github.com/Juwon1405/GitNote/blob/main/Resources/[Cheatsheet]%20macos-unified-log-triage.md

set -uo pipefail

OUT="${1:-./launchd_audit_$(hostname)_$(date +%Y%m%d_%H%M%S)}"
mkdir -p "$OUT"

echo "==> Collecting launchd persistence inventory into: $OUT"
echo

# ------------------------------------------------------------------
# Phase 1 — full inventory of all four locations
# ------------------------------------------------------------------
LOCATIONS=(
  "/System/Library/LaunchAgents"
  "/System/Library/LaunchDaemons"
  "/Library/LaunchAgents"
  "/Library/LaunchDaemons"
)

# Add per-user LaunchAgents
for home in /Users/*; do
    [ -d "$home/Library/LaunchAgents" ] && LOCATIONS+=("$home/Library/LaunchAgents")
done
# Also check current user's home if running as user
[ -d "$HOME/Library/LaunchAgents" ] && LOCATIONS+=("$HOME/Library/LaunchAgents")

echo "==> Phase 1 — full inventory"
{
  for loc in "${LOCATIONS[@]}"; do
    echo "## $loc"
    if [ -d "$loc" ]; then
      ls -la "$loc"/*.plist 2>/dev/null || echo "(empty)"
    else
      echo "(directory not present)"
    fi
    echo
  done
} > "$OUT/01_inventory.txt"

# ------------------------------------------------------------------
# Phase 2 — extract suspicious patterns
# ------------------------------------------------------------------
echo "==> Phase 2 — suspicious patterns"

> "$OUT/02_suspicious.txt"

for loc in "${LOCATIONS[@]}"; do
    [ ! -d "$loc" ] && continue

    for plist in "$loc"/*.plist; do
        [ ! -f "$plist" ] && continue

        # Convert binary plists to xml for grepping
        content=$(plutil -convert xml1 -o - "$plist" 2>/dev/null || cat "$plist")

        # Pattern 1 — RunAtLoad in user-writable location
        if [[ "$loc" =~ ^/Users/ || "$loc" =~ ^$HOME ]]; then
            if echo "$content" | grep -q "<key>RunAtLoad</key>" &&
               echo "$content" | grep -A1 "<key>RunAtLoad</key>" | grep -q "<true/>"; then
                echo "[SUSPICIOUS] User-writable LaunchAgent with RunAtLoad=true:" >> "$OUT/02_suspicious.txt"
                echo "  Path: $plist" >> "$OUT/02_suspicious.txt"
                echo "  MITRE: T1543.004" >> "$OUT/02_suspicious.txt"
                echo "" >> "$OUT/02_suspicious.txt"
            fi
        fi

        # Pattern 2 — command paths in temp / cache
        for danger_path in "/tmp/" "/private/tmp/" "/Users/Shared/" "/Library/Caches/" "Caches/"; do
            if echo "$content" | grep -q "$danger_path"; then
                echo "[SUSPICIOUS] Plist references command in unusual location:" >> "$OUT/02_suspicious.txt"
                echo "  Path: $plist" >> "$OUT/02_suspicious.txt"
                echo "  Reference: $danger_path" >> "$OUT/02_suspicious.txt"
                echo "  MITRE: T1543.004" >> "$OUT/02_suspicious.txt"
                echo "" >> "$OUT/02_suspicious.txt"
                break
            fi
        done

        # Pattern 3 — command paths in /Users/<user>/.local, ~/.config etc. (uncommon for legit launchd)
        if echo "$content" | grep -qE '/Users/[^/]+/\.(local|config|cache|hidden)'; then
            echo "[SUSPICIOUS] Plist references hidden home subdirectory:" >> "$OUT/02_suspicious.txt"
            echo "  Path: $plist" >> "$OUT/02_suspicious.txt"
            echo "  MITRE: T1543.004 + T1564.001 (hidden file/dir)" >> "$OUT/02_suspicious.txt"
            echo "" >> "$OUT/02_suspicious.txt"
        fi

        # Pattern 4 — System LaunchDaemons not owned by root
        if [[ "$loc" =~ ^/Library/LaunchDaemons$ || "$loc" =~ ^/System/Library/LaunchDaemons$ ]]; then
            owner=$(stat -f '%Su' "$plist" 2>/dev/null)
            if [ -n "$owner" ] && [ "$owner" != "root" ]; then
                echo "[CRITICAL] System LaunchDaemon NOT owned by root:" >> "$OUT/02_suspicious.txt"
                echo "  Path: $plist" >> "$OUT/02_suspicious.txt"
                echo "  Owner: $owner" >> "$OUT/02_suspicious.txt"
                echo "  MITRE: T1543.004" >> "$OUT/02_suspicious.txt"
                echo "" >> "$OUT/02_suspicious.txt"
            fi
        fi

        # Pattern 5 — code-signing check (best-effort)
        prog=$(echo "$content" | grep -A1 "<key>Program</key>" | grep "<string>" | sed -E 's/.*<string>(.*)<\/string>.*/\1/' | head -1)
        if [ -z "$prog" ]; then
            prog=$(echo "$content" | grep -A1 "<key>ProgramArguments</key>" | grep "<string>" | sed -E 's/.*<string>(.*)<\/string>.*/\1/' | head -1)
        fi
        if [ -n "$prog" ] && [ -f "$prog" ]; then
            sig=$(codesign -dv "$prog" 2>&1 | grep -i "Authority")
            if [ -z "$sig" ] || [[ ! "$sig" =~ "Apple" && ! "$sig" =~ "Developer ID" ]]; then
                echo "[WARNING] Plist references unsigned/non-Apple binary:" >> "$OUT/02_suspicious.txt"
                echo "  Plist: $plist" >> "$OUT/02_suspicious.txt"
                echo "  Binary: $prog" >> "$OUT/02_suspicious.txt"
                echo "  Signing: ${sig:-(no signature)}" >> "$OUT/02_suspicious.txt"
                echo "" >> "$OUT/02_suspicious.txt"
            fi
        fi
    done
done

# ------------------------------------------------------------------
# Phase 3 — recently modified plists (last 30 days)
# ------------------------------------------------------------------
echo "==> Phase 3 — recently modified plists (last 30d)"
{
  for loc in "${LOCATIONS[@]}"; do
    [ ! -d "$loc" ] && continue
    find "$loc" -name "*.plist" -mtime -30 2>/dev/null
  done
} | sort -u > "$OUT/03_recent_30d.txt"

# ------------------------------------------------------------------
# Phase 4 — currently loaded launchd jobs
# ------------------------------------------------------------------
echo "==> Phase 4 — currently loaded launchd jobs"
launchctl list > "$OUT/04_loaded_jobs.txt" 2>/dev/null

# ------------------------------------------------------------------
# Phase 5 — summary report
# ------------------------------------------------------------------
{
  echo "## launchd Persistence Audit Summary"
  echo "Host: $(hostname)"
  echo "Date: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  echo "Run as: $(whoami)"
  echo
  echo "## Counts"
  total_plists=0
  for loc in "${LOCATIONS[@]}"; do
    [ ! -d "$loc" ] && continue
    count=$(ls "$loc"/*.plist 2>/dev/null | wc -l | tr -d ' ')
    printf "  %-50s  %4d plists\n" "$loc" "$count"
    total_plists=$((total_plists + count))
  done
  echo "  TOTAL: $total_plists plists"
  echo
  echo "## Findings"
  suspicious_count=$(grep -c "^\[" "$OUT/02_suspicious.txt" 2>/dev/null || echo 0)
  recent_count=$(wc -l < "$OUT/03_recent_30d.txt" | tr -d ' ')
  loaded_count=$(wc -l < "$OUT/04_loaded_jobs.txt" | tr -d ' ')
  echo "  Suspicious patterns: $suspicious_count"
  echo "  Recently modified (30d): $recent_count"
  echo "  Currently loaded jobs: $loaded_count"
  echo
  echo "## Files"
  ls -la "$OUT/"
  echo
  echo "## Hash manifest"
  ( cd "$OUT" && shasum -a 256 *.txt > SHA256SUMS )
  cat "$OUT/SHA256SUMS"
} > "$OUT/00_SUMMARY.txt"

cat "$OUT/00_SUMMARY.txt"
echo
echo "==> Audit complete. Review: $OUT/02_suspicious.txt first."
