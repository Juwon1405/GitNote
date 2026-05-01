# [Cheatsheet] macOS Unified Log Triage

> macOS DFIR is hard because **Apple buried everything in the Unified Log** and the `log` command's predicate language is poorly documented. Here are the predicates that actually work for IR.
>
> **Last updated:** 2026-05-01

---

## 🎯 The two paths to read the Unified Log

### Path 1 — Live host (post-incident, before reboot)
```bash
# Last 24 hours, filtered to security-relevant predicates
log show --last 24h --predicate '<see below>' --info --debug

# Stream live (tail -f equivalent)
log stream --predicate '<see below>' --info
```

### Path 2 — Dead-disk forensics (offline analysis)
```bash
# Logs live in /private/var/db/diagnostics/ — copy the whole tree
# Then on your analysis Mac:
log show --archive /path/to/diagnostics_archive --predicate '<...>' --info
```

**Key flags:**
- `--info` — includes informational messages (most security stuff is here)
- `--debug` — includes debug (massive volume; use sparingly)
- `--last <Nh|Nd>` — time range (e.g. `--last 7d`)
- `--start "2026-04-22 00:00:00" --end "2026-04-22 23:59:59"` — exact range

---

## 🚨 The 12 predicates that catch most intrusions

### 1. SSH login attempts (T1110.001 / T1078)
```
process == "sshd" AND (eventMessage CONTAINS "Accepted" OR eventMessage CONTAINS "Failed")
```

### 2. sudo / privilege escalation (T1548.003)
```
process == "sudo" AND eventMessage CONTAINS "TTY="
```
Look for sudo invocations to root from non-admin accounts.

### 3. TCC privacy database modifications (T1098)
```
subsystem == "com.apple.TCC" AND eventMessage CONTAINS "modify"
```
TCC (Transparency, Consent, and Control) governs what each app can access. Attackers granting themselves Full Disk Access shows here.

### 4. New launchd jobs (T1543.004 / T1543.001)
```
process == "launchd" AND (eventMessage CONTAINS "registering" OR eventMessage CONTAINS "loaded")
```
Pair with file-system check on `~/Library/LaunchAgents/` and `/Library/Launch{Agents,Daemons}/`.

### 5. Quarantine bypass (T1553.001)
```
subsystem == "com.apple.LaunchServices" AND eventMessage CONTAINS "quarantine"
```
Attackers strip `com.apple.quarantine` extended attribute to bypass Gatekeeper.

### 6. XPC service registration (T1543)
```
subsystem == "com.apple.xpc.launchd" AND eventMessage CONTAINS "Service"
```

### 7. Network configuration changes (T1556 / T1565)
```
subsystem == "com.apple.SystemConfiguration" AND eventMessage CONTAINS "DNS"
```

### 8. Defender / XProtect / MRT events (T1562.001)
```
subsystem CONTAINS "com.apple.XProtect" OR subsystem CONTAINS "com.apple.MRT"
```

### 9. Authentication failures across all subsystems
```
eventMessage CONTAINS[c] "authentication failed" OR
eventMessage CONTAINS[c] "auth failure" OR
eventMessage CONTAINS[c] "login failed"
```

### 10. Bash / zsh execution (when shell is logged)
```
process IN {"bash", "zsh", "sh"} AND eventMessage CONTAINS "executed"
```
(Note: shell command logging is rarely on by default — see Audit Policy below.)

### 11. Code signing failures (T1553.002 / T1036.001)
```
subsystem == "com.apple.LaunchServices" AND eventMessage CONTAINS "code signing"
```

### 12. Endpoint Security Framework events (T1562.001)
```
subsystem == "com.apple.endpointsecurity"
```

---

## 🔍 The "what just happened in the last 5 minutes" command

```bash
log show --last 5m \
  --predicate '(eventMessage CONTAINS[c] "fail" OR eventMessage CONTAINS[c] "denied" OR eventMessage CONTAINS[c] "error") AND messageType == "Error"' \
  --style compact
```

This is your **alarm-bell first pass** when you've just gotten on a host.

---

## 🛠️ Persistence locations to enumerate IN ADDITION to log

The Unified Log doesn't replace artifact collection — it complements it. You still need to enumerate:

```bash
# LaunchAgents (per-user persistence)
ls -la ~/Library/LaunchAgents/ /Library/LaunchAgents/

# LaunchDaemons (root persistence)
ls -la /Library/LaunchDaemons/

# Login items (older but still used)
osascript -e 'tell application "System Events" to get the name of every login item'
defaults read com.apple.loginitems

# Cron / at jobs
ls -la /var/at/jobs/ /etc/cron.d/ /etc/periodic/

# Startup items (legacy but still parsed by macOS)
ls -la /Library/StartupItems/

# Kernel extensions and System Extensions
kextstat | grep -v com.apple
systemextensionsctl list
```

For a single-script collector that does all of this + the unified log queries, see [`yushin-mac-artifact-collector`](https://github.com/Juwon1405/yushin-mac-artifact-collector).

---

## 📁 Where evidence actually lives on disk

| Artifact | Path |
|---|---|
| Unified Log archive | `/private/var/db/diagnostics/` |
| TCC database | `/Library/Application Support/com.apple.TCC/TCC.db` (system) + `~/Library/Application Support/com.apple.TCC/TCC.db` (per-user) |
| Quarantine database | `~/Library/Preferences/com.apple.LaunchServices.QuarantineEventsV2` |
| FSEvents | `/.fseventsd/` (filesystem-level event journal) |
| Spotlight metadata | `/.Spotlight-V100/` |
| KnowledgeC (user activity) | `~/Library/Application Support/Knowledge/knowledgeC.db` |
| Browser histories | `~/Library/Application Support/{Google/Chrome,Microsoft Edge,Firefox,Safari}/...` |
| zsh / bash history | `~/.zsh_history`, `~/.bash_history` |
| Login history | `last` command (reads `/var/log/wtmp`) |
| Defender / EDR logs | depends on vendor — typically `/var/log/<vendor>/` |

---

## 🎯 The high-yield 30-minute macOS triage

```bash
#!/bin/bash
# Quick macOS triage — runs in ~30 minutes
OUT=~/triage_$(hostname)_$(date +%Y%m%d_%H%M%S)
mkdir -p $OUT

# 1. Unified log — last 7 days, security predicates
log show --last 7d \
  --predicate '(process == "sshd" OR process == "sudo" OR process == "launchd" OR subsystem == "com.apple.TCC" OR subsystem CONTAINS "com.apple.XProtect")' \
  --style compact > $OUT/unified_log_security.txt

# 2. Persistence inventory
ls -la ~/Library/LaunchAgents/ /Library/LaunchAgents/ /Library/LaunchDaemons/ 2>&1 > $OUT/persistence.txt

# 3. Login + TCC + Quarantine snapshots
last > $OUT/last.txt
sqlite3 -readonly "/Library/Application Support/com.apple.TCC/TCC.db" "SELECT * FROM access" > $OUT/tcc_system.txt 2>/dev/null
sqlite3 -readonly ~/"Library/Preferences/com.apple.LaunchServices.QuarantineEventsV2" \
  "SELECT * FROM LSQuarantineEvent ORDER BY LSQuarantineTimeStamp DESC LIMIT 100" > $OUT/quarantine.txt

# 4. Network state
netstat -an | head -200 > $OUT/netstat.txt
lsof -i -n | head -200 > $OUT/lsof.txt
scutil --dns > $OUT/dns.txt

# 5. Running processes + loaded kexts
ps aux > $OUT/ps.txt
kextstat > $OUT/kextstat.txt
systemextensionsctl list > $OUT/sysext.txt 2>&1

# 6. Browser histories (read-only copies)
for browser in "Google/Chrome" "Microsoft Edge" "Firefox" "Safari"; do
  src=~/"Library/Application Support/$browser"
  [ -d "$src" ] && cp -R "$src" "$OUT/browser_$browser" 2>/dev/null
done

# 7. Hash everything for chain-of-custody
find $OUT -type f -exec shasum -a 256 {} \; > $OUT/SHA256SUMS

echo "Triage complete: $OUT"
ls -la $OUT
```

Run with `sudo` for system-level coverage. Companion: [`yushin-mac-artifact-collector`](https://github.com/Juwon1405/yushin-mac-artifact-collector) does this and more, with timeout protection and supply-chain IOC sweeps.

---

## 📊 Audit policy — what to enable for richer logs

macOS Unified Log is **always on**, but specific subsystems can be tuned. Most useful:

```bash
# Increase log retention (default is small)
sudo log config --mode "level:info" --subsystem com.apple.security
sudo log config --mode "level:info" --subsystem com.apple.TCC

# Enable Endpoint Security Framework (T1562.001 detection)
# (Requires kernel extension or System Extension from your EDR vendor)

# Privacy auditing — monitor TCC modifications
defaults write /Library/Preferences/com.apple.security.libraryvalidation.plist DisableLibraryValidation -bool false
```

Note: Apple removed several useful logging behaviors in Sequoia (macOS 15) — what worked on Big Sur may not work on the latest. Always verify against the target version.

---

## 📚 References

- **Sarah Edwards · mac4n6.com** — The reference site for macOS DFIR. Required reading.
- **Patrick Wardle · objective-see.org** — The Art of Mac Malware (free PDF). Persistence catalog.
- **Apple — `man log`** — `log(1)` man page is the only authoritative predicate reference.
- **Yamato Security — EnableWindowsLogSettings** doesn't apply to Mac, but the *philosophy* (audit policy = required prerequisite) does.
- **The Sleuth Kit / Autopsy macOS modules** — disk-level analysis when live-host triage isn't possible.
- **`yushin-mac-artifact-collector`** — companion repo by the same author.
- **`yushin-mac-forensics-platform`** — Flask-based analysis platform that ingests the collector's output.

---

## ↩️ Back

← [Resources/](../Resources/) · [GitNote root](../README.md)
