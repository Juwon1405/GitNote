# [Cheatsheet] EVTX Threat Hunting 2026

> Practical Windows Event Log triage cheatsheet for DFIR analysts. Combines the **most-cited 2026 TTPs** (DFIR Report case studies, Mandiant M-Trends 2026, Check Point's *The Gentlemen* analysis) with **field-tested EVTX queries**.
>
> **Last updated:** 2026-05-01

---

## 🎯 The 12 EIDs that catch 80% of intrusions

If you only audit / parse / hunt these twelve, you'll catch most modern Windows intrusions:

| EID | Channel | What it tells you |
|---:|---|---|
| **4624** | Security | **Successful logon.** Logon-type 9 = admin token; 10 = RDP; 3 = network |
| **4625** | Security | **Failed logon.** Burst pattern → brute force / password spray |
| **4634** / **4647** | Security | Logoff (machine / user-initiated) — pair with 4624 to get session duration |
| **4648** | Security | **Explicit credential use** — `runas`, scheduled task creation under another user. Often **first hop** in lateral movement chain |
| **4672** | Security | **Special privileges granted** — admin token activated. If not preceded by T1003/T1558/T1068, suspect **Golden Ticket** |
| **4688** | Security | **Process creation** (when CommandLine logging is enabled — see § Audit Policy below) |
| **4697** | Security | **Service installed** — classic PsExec lateral movement or persistence |
| **4720** / **4732** | Security | New user / added to admin group |
| **5140** / **5145** | Security | Network share access — file server lateral movement |
| **5145** | Security | Detailed share access — useful for ransomware staging detection |
| **1** | Sysmon | Process creation (Sysmon-rich, includes hashes + parent) |
| **3** | Sysmon | Network connection — C2 / data exfil |
| **11** | Sysmon | File create — ransomware extension changes, dropper activity |
| **13** | Sysmon | Registry value set — Run/RunOnce persistence |

---

## 🚨 Top 10 detections to run first (Hayabusa-friendly)

Each one is a **single Sigma rule** you can run via [Hayabusa](https://github.com/Yamato-Security/hayabusa) on a directory of EVTX files.

### 1. LSASS dump via comsvcs.dll (T1003.001)
```
EID 1 OR 4688
CommandLine contains: "comsvcs.dll" AND "MiniDump"
Parent: rundll32.exe
```
**Why it matters:** The single most common credential access TTP in 2025-2026. LOLBin path (no extra binary needed).

### 2. Pass-the-Hash chain (T1550.002)
```
4624 LogonType=9 OR LogonType=3
AuthenticationPackage=NTLM
LogonProcess=NtLmSsp (NOT Kerberos)
TargetUserName=Administrator OR Domain Admin
```
**Pivot:** chain into 5145 (share access) within 60 seconds.

### 3. Anti-forensic timestomp (T1070.006)
```
$SI < $FN by > 1 second on executable file
(MFT analysis — see [mft-timestomp-detection.md])
```

### 4. Service install for lateral movement (T1543.003 + T1021.002)
```
EID 7045
ImagePath contains: "\\\\" OR HEX-encoded PowerShell OR Base64
ServiceName: random 8-char name (PsExec signature)
```

### 5. Recovery denial (T1490) — ransomware predecessor
```
EID 1 OR 4688
CommandLine contains:
  "vssadmin delete shadows" OR
  "wbadmin delete catalog" OR
  "bcdedit /set {default} recoveryenabled No" OR
  "wevtutil cl"
```
**M-Trends 2026 #1 ransomware trend.**

### 6. Scheduled task persistence (T1053.005)
```
EID 4698 OR 4702
TaskName contains: "Update" OR "Microsoft\\Windows\\System\\WindowsUpdate"
       (attackers love impersonating legit task names)
Author NOT in: SYSTEM, NT AUTHORITY, BUILTIN
```

### 7. WMI lateral movement (T1047)
```
EID 4688
ParentImage: WmiPrvSE.exe
CommandLine: contains cmd.exe OR powershell.exe
SourceUserName != local user (network logon precedes)
```

### 8. PowerShell with encoded command (T1059.001 + T1027)
```
EID 4104 OR 4688
CommandLine contains: "-EncodedCommand" OR "-enc " OR "-e "
       (case-insensitive; -e is the danger flag)
ScriptBlockText decodes to: IEX, DownloadString, FromBase64String
```

### 9. Kerberoasting (T1558.003)
```
EID 4769
TicketEncryptionType: 0x17 (RC4-HMAC) — modern systems should use AES (0x12)
TicketOptions: 0x40810010 (without canonicalize flag)
ServiceName: HOST/* OR MSSQL/*
```

### 10. RDP from external IP (T1021.001 + T1133)
```
EID 4624 LogonType=10
IpAddress: NOT in RFC1918 (10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16)
       AND NOT corporate egress
```

---

## 🛠️ Audit policy required for these to actually work

Your EVTX hunt is only as good as what's logged. **75% of Sigma rules need these turned on:**

```powershell
# Enable command-line logging in 4688 (CRITICAL — most Sigma rules depend on this)
auditpol /set /subcategory:"Process Creation" /success:enable /failure:enable
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\Audit" /v ProcessCreationIncludeCmdLine_Enabled /t REG_DWORD /d 1 /f

# PowerShell logging
reg add "HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows\PowerShell\ScriptBlockLogging" /v EnableScriptBlockLogging /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows\PowerShell\ModuleLogging" /v EnableModuleLogging /t REG_DWORD /d 1 /f

# WMI activity (for T1047)
auditpol /set /subcategory:"DCOM" /success:enable /failure:enable
```

Reference: [Yamato Security — EnableWindowsLogSettings](https://github.com/Yamato-Security/EnableWindowsLogSettings) (independent third-party project; their `.bat` script automates the above).

---

## 🔬 Hayabusa one-liners I actually use

```bash
# 1) Quick alarm-bell scan — high-severity hits only
hayabusa csv-timeline -d /evidence/EVTX/ -m high -o triage.csv

# 2) Threat-hunting mode (more rules, more FPs, but catches subtle stuff)
hayabusa csv-timeline -d /evidence/EVTX/ \
    --include-tag detection.threat_hunting \
    -o hunt.csv

# 3) Pivot keywords — which user / host / process is anomalous?
hayabusa pivot-keywords-list -d /evidence/EVTX/ -o pivot.txt

# 4) Logon summary (admin token activations, RDP sources, etc.)
hayabusa logon-summary -d /evidence/EVTX/ -o logon.txt

# 5) Search for a specific IP / hash / username
hayabusa search -d /evidence/EVTX/ -k "evil.attacker.com" -o ioc-hits.csv
```

---

## 📚 The corpus to read

- **[The DFIR Report](https://thedfirreport.com)** — every published case study has detailed EVTX timelines and IOCs
- **[hayabusa-rules](https://github.com/Yamato-Security/hayabusa-rules)** (Yamato Security, third-party) — 4000+ curated Sigma rules
- **[Sigma rules main repo](https://github.com/SigmaHQ/sigma)** — upstream
- **[JPCERT/CC — Detecting Lateral Movement through Tracking Event Logs](https://blogs.jpcert.or.jp/en/2017/12/research-report-released-detecting-lateral-movement-through-tracking-event-logs-version-2.html)** — still the canonical reference for AD-centric event log analysis
- **[Sean Metcalf · adsecurity.org](https://adsecurity.org)** — for everything 4624 / 4672 / 4768 / 4769

---

## ⚙️ Quick triage workflow (60-minute initial answer)

1. **Acquire.** Pull EVTX from `%SystemRoot%\System32\winevt\Logs\` — `Security.evtx`, `System.evtx`, `Application.evtx`, `Microsoft-Windows-PowerShell%4Operational.evtx`, `Microsoft-Windows-Sysmon%4Operational.evtx` minimum.
2. **Hayabusa pass.** Run `csv-timeline -m high` first → 30-second pass for critical hits.
3. **Logon summary.** `hayabusa logon-summary` → who logged on when, from where.
4. **Pivot to IOCs.** Take any new domain / IP / hash → run `search -k`.
5. **Timeline.** Bring `triage.csv` into Timeline Explorer → set `Time` as the sort key, group by EventID, hunt anomalies.
6. **Cross-reference.** Match suspicious processes against [The DFIR Report](https://thedfirreport.com) case studies for similar TTP signatures.

---

## ↩️ Back

← [Resources/](../Resources/) · [GitNote root](../README.md)
