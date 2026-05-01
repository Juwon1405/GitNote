# [Cheatsheet] MFT Timestomp Detection (T1070.006)

> The single highest-value forensic finding in modern intrusions. If you find a timestomp, you've usually found the **earliest persistence**, often days or weeks before the noisy alert that brought you in.
>
> **Last updated:** 2026-05-01

---

## 🎯 What timestomping is

Windows tracks **two sets of timestamps** per file:
- **`$STANDARD_INFORMATION` ($SI)** — what `dir`, Explorer, and most APIs see. **Easily writable** by attackers (`SetFileTime` API, `timestomp.exe`, PowerShell `[System.IO.File]::SetLastWriteTime`).
- **`$FILE_NAME` ($FN)** — kept inside the MFT directory entry. Only updated by **kernel-internal MFT operations** (file create, rename). Not exposed by the user-mode API.

Attackers timestomp `$SI` to hide their tools (make them look like they were created in 2018 when Windows was installed). They almost never timestomp `$FN` — it's much harder.

**The detection:** if `$SI` < `$FN` by more than ~1 second, the file was timestomped. **`$SI` cannot legitimately predate `$FN` for a file the OS created.**

---

## 🚨 The detection logic

```
For each file in MFT:
    if $SI.created < $FN.created - 1 second:
        ALERT: timestomped (created)
    if $SI.modified < $FN.modified - 1 second:
        ALERT: timestomped (modified)
    if any($SI fields) < any($FN fields) - 1 hour:
        SEVERITY: critical (clearly intentional, not clock skew)
```

**Tolerance window:** allow 1 second for legitimate clock-resolution differences. >1 hour is a near-guaranteed adversary action.

**Severity escalator:** if the timestomped file is also an **executable** (`.exe`, `.dll`, `.ps1`, `.bat`, `.lnk` shortcut to executable), escalate to critical and treat as confirmed adversary persistence.

---

## 🛠️ How to actually run this

### Option 1 — MFTECmd (Eric Zimmerman) — fastest, most-supported

```bash
# Parse $MFT into CSV
MFTECmd.exe -f C:\evidence\$MFT --csv C:\out --csvf mft.csv

# Filter for timestomp candidates with PowerShell or Python
Import-Csv C:\out\mft.csv | Where-Object {
    ([datetime]$_.Created0x10) -lt ([datetime]$_.Created0x30).AddSeconds(-1)
} | Export-Csv timestomp_candidates.csv
```

### Option 2 — analyzeMFT (Python) — script-friendly

```bash
pip install analyzeMFT
analyzemft -f $MFT -o mft_full.csv
# Then post-process with the snippet below
```

### Option 3 — `mft_timestomp_detector.py` (companion CodeSnippet)

I wrote a focused Python script that does just the timestomp detection — no full MFT dump needed. See [`CodeSnippets/mft_timestomp_detector.py`](../CodeSnippets/mft_timestomp_detector.py).

```bash
python3 mft_timestomp_detector.py /evidence/MFT.csv --tolerance 1 --executables-only
```

---

## 🎬 The 4 patterns to look for in the output

### Pattern 1 — Single tool, deep predating (high confidence)
```
file.exe
  $SI.created  = 2019-08-15 10:22:33  (← attacker spoofed)
  $FN.created  = 2026-04-22 03:14:17  (← real)
  delta: ~7 years
```
This is the canonical signature. Treat as confirmed persistence at $FN.created (the real time).

### Pattern 2 — Cluster of files with identical $SI (mass timestomp)
```
attacker_dir/
  ├─ tool1.exe   $SI: 2018-05-04 11:00:00, $FN: 2026-04-22 03:14:18
  ├─ tool2.exe   $SI: 2018-05-04 11:00:00, $FN: 2026-04-22 03:14:18
  └─ tool3.exe   $SI: 2018-05-04 11:00:00, $FN: 2026-04-22 03:14:19
```
The attacker ran `timestomp -f $time *` to bulk-stamp a tool drop. **Identical $SI across multiple files in the same directory** is itself a strong signal even if the deltas are small.

### Pattern 3 — $SI.modified < $FN.created (impossible without timestomp)
```
config.xml
  $SI.modified = 2024-11-02 09:31:00  (← claimed last edit)
  $FN.created  = 2026-04-22 04:00:00  (← actual file creation)
```
A file cannot have been modified *before* it was created. This is a logical impossibility; the only way it happens is timestomp.

### Pattern 4 — Predating across the install boundary
```
suspicious.dll in C:\Windows\System32\
  $SI:  2009-07-13 23:54:46  (Windows install epoch)
  $FN:  2026-04-22 03:15:01
```
Attackers love spoofing to the Windows install date because it makes the file blend in with system files. **Files that `$SI`-claim to predate the OS install but `$FN`-actually exist after** are a high-confidence adversary signal.

---

## 🔗 What to pivot to once you find a timestomp

1. **Anchor your investigation timeline at `$FN.created`** — not `$SI`. That's when the file actually appeared.
2. **Rewind 24 hours from `$FN.created`** and check:
   - 4624 logon events (who was on the box?)
   - 4688 process creation (what was running before the file dropped?)
   - 5145 share access (was a share mounted that delivered the file?)
   - Sysmon EID 11 (file create) for files in the same directory
3. **Check parent directory** — what dropped this file? Often a webshell `cmd.exe` or `powershell.exe` exec.
4. **Hash the file** and pivot in VirusTotal / Polarity / your TI platform.
5. **Look for sibling files with identical $SI** — the timestomp pattern usually applies to a whole tool drop, not one file.

---

## 📊 dart-corr / agentic-DART contradiction trigger (reference)

In the `agentic-dart` playbook v3, this exact scenario is encoded as a contradiction handler:

```yaml
contradiction_triggers:
  - id: timestomp_predates_alert
    source_a: mft_si_fn_mismatch
    source_b: alert_timestamp
    rule: "If $SI < $FN AND mismatch_ts < alert_ts, persistence pre-existed"
    threshold_seconds: 1
    pivot: hunt_earlier_in_timeline
    severity: critical
    mitre: T1070.006
    ads_summary:
      goal: "Detect anti-forensic timestomping that hides earlier persistence"
      validation: "Atomic Red Team T1070.006-1"
      response: "Hunt for persistence in T-30d window; this is not a fresh case"
```

See [agentic-dart/dart_playbook/senior-analyst-v3.yaml](https://github.com/Juwon1405/agentic-dart/blob/main/dart_playbook/senior-analyst-v3.yaml).

---

## 🛡️ Detection in production — Sigma rule

```yaml
title: Suspicious MFT Timestomping ($SI predates $FN)
id: 8a1b2c3d-...
status: experimental
description: Detects files where $STANDARD_INFORMATION created predates $FILE_NAME created
logsource:
  category: file_change
  product: windows
detection:
  selection:
    si_created: '*'
    fn_created: '*'
  condition: |
    selection AND (TimeDiff(fn_created, si_created) > 1)
fields:
  - file_path
  - si_created
  - fn_created
  - delta_seconds
level: high
tags:
  - attack.defense_evasion
  - attack.t1070.006
```

---

## 📚 References

- **NIST SP 800-86** — Forensic timestamp principles
- **Eric Zimmerman, MFTECmd** — [github.com/EricZimmerman/MFTECmd](https://github.com/EricZimmerman/MFTECmd)
- **The DFIR Report — Pass-the-Hash with timestomp case** — pattern that motivated this cheatsheet
- **Atomic Red Team T1070.006** — [atomicredteam.io/defense-evasion/T1070.006](https://atomicredteam.io/defense-evasion/T1070.006)
- **MITRE ATT&CK T1070.006** — [attack.mitre.org/techniques/T1070/006](https://attack.mitre.org/techniques/T1070/006)

---

## ↩️ Back

← [Resources/](../Resources/) · [GitNote root](../README.md)
