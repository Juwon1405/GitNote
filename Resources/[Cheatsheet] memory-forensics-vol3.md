# [Cheatsheet] Memory Forensics with Volatility 3 (2026)

> Quick-reference for **Volatility 3 v2.27** (released 2026-01-29). Focuses on the plugins I actually use in IR engagements, not the encyclopedic list.
>
> **Last updated:** 2026-05-01

---

## 🎯 Vol3 vs Vol2 in 30 seconds

| | Vol2 (legacy) | **Vol3 (current)** |
|---|---|---|
| Status | **Archived** | Active development |
| Python | 2 (EOL) | **3.8+** |
| Profiles | Manual `--profile=Win10x64_19041` | **Auto-detected** from PDB symbols |
| Performance | Single-threaded | Multi-threaded layers |
| Symbol files | bundled per OS version | downloaded on demand from Microsoft |
| Plugin namespace | `windows.pslist`, `linux.pslist`, etc. (no prefix) | `windows.pslist.PsList` (full path) |

**Use Vol3 for everything.** Vol2 only if you're working with very old samples (Win XP era) or specific archived plugins not yet ported.

---

## 🚀 Setup

```bash
# Install
pip install volatility3 --upgrade

# Verify
vol --version    # should show 2.27.0+ as of May 2026

# First run — will download Microsoft PDB symbols (cached after)
vol -f memory.raw windows.info.Info
```

**For Linux/macOS samples** you need symbol tables matching the *exact* kernel version. Download from:
- Linux: https://github.com/Abyss-W4tcher/volatility3-symbols (community-maintained)
- macOS: https://downloads.volatilityfoundation.org/volatility3/symbols/mac.zip

Place `.zip` files (do NOT extract) into `volatility3/symbols/`.

---

## 🔍 The Top 12 plugins for IR triage

### 1. `windows.info.Info` — orient yourself
```bash
vol -f mem.raw windows.info.Info
```
What you learn: OS version, kernel build, system time, # CPUs, # processes. **Always run this first** to confirm the sample is what you expect.

### 2. `windows.pslist.PsList` — process listing
```bash
vol -f mem.raw windows.pslist.PsList
```
Standard process tree. Compare against `pstree` for the parent chain.

### 3. `windows.pstree.PsTree` — parent/child relationships
```bash
vol -f mem.raw windows.pstree.PsTree
```
**The first hunting plugin.** Look for:
- `cmd.exe` / `powershell.exe` parented by `WINWORD.EXE`, `Excel.EXE`, `outlook.exe` (macro execution)
- `rundll32.exe` parented by `explorer.exe` with no command-line context (process injection?)
- Nested `cmd → cmd → powershell` chains (post-exploitation tooling)

### 4. `windows.psscan.PsScan` — find HIDDEN processes
```bash
vol -f mem.raw windows.psscan.PsScan
```
Walks the `_EPROCESS` pool tags directly, finding processes that are **unlinked from the active process list** (rootkit / DKOM). Diff against `pslist` — anything in `psscan` but not `pslist` is suspicious.

### 5. `windows.cmdline.CmdLine` — what command line ran each process?
```bash
vol -f mem.raw windows.cmdline.CmdLine
```
Critical for understanding what attackers actually executed. Look for:
- `-EncodedCommand` / `-enc` PowerShell
- `comsvcs.dll MiniDump` (LSASS dumping)
- Long base64 blobs

### 6. `windows.netscan.NetScan` — active connections
```bash
vol -f mem.raw windows.netscan.NetScan
```
TCP/UDP connections, sockets, listeners. **Cross-reference foreign IPs against threat intel** (VirusTotal, AbuseIPDB).

### 7. `windows.malfind.Malfind` — injected code regions
```bash
vol -f mem.raw windows.malfind.Malfind
```
Finds memory regions with `RWX` (read+write+execute) permissions and hex-dumps the start. Common adversary signal: process injection, reflective DLL loading. **Look for MZ headers** in the hex output.

### 8. `windows.dlllist.DllList` — what DLLs are loaded per process?
```bash
vol -f mem.raw windows.dlllist.DllList --pid <PID>
```
Suspicious: DLLs in `%TEMP%`, `%APPDATA%`, or unsigned DLLs in system processes.

### 9. `windows.handles.Handles` — what objects does a process have open?
```bash
vol -f mem.raw windows.handles.Handles --pid <PID>
```
Look for:
- `\Device\PhysicalMemory` (rare; should be MS Defender, Sysmon, or attacker)
- Named pipes ending in random hex (PsExec service install)
- Mutexes matching known malware patterns

### 10. `windows.registry.hivelist.HiveList` + `windows.registry.printkey.PrintKey`
```bash
# List loaded hives
vol -f mem.raw windows.registry.hivelist.HiveList

# Dump Run keys
vol -f mem.raw windows.registry.printkey.PrintKey \
    --key 'Software\Microsoft\Windows\CurrentVersion\Run'
```
Persistence! Run keys, RunOnce, services, scheduled tasks — all readable from memory hives.

### 11. `windows.dumpfiles.DumpFiles` — extract files from memory
```bash
vol -f mem.raw windows.dumpfiles.DumpFiles --pid <PID> --dump
```
Pulls cached files from VAD regions. Useful for extracting in-memory droppers, decrypted ransomware payloads, etc.

### 12. `windows.svcscan.ScanSvc` — services
```bash
vol -f mem.raw windows.svcscan.ScanSvc
```
Persistence + lateral-movement TTPs. Look for services with random names (PsExec) or paths in non-standard locations.

---

## 🐧 Linux equivalents (Volatility 3 v2.7+)

```bash
vol -f linux.dump linux.pslist.PsList                     # processes
vol -f linux.dump linux.pstree.PsTree                     # parent chain
vol -f linux.dump linux.psaux.PsAux                       # cmdline
vol -f linux.dump linux.bash.Bash                         # bash history (HOT — recovers in-memory bash history)
vol -f linux.dump linux.lsmod.Lsmod                       # loaded kernel modules (rootkits)
vol -f linux.dump linux.check_idt.Check_idt               # IDT hooks (rootkits)
vol -f linux.dump linux.check_syscall.Check_syscall       # syscall table hooks (rootkits)
vol -f linux.dump linux.proc.Maps --pid <PID>             # memory map of process (RWX hunting)
vol -f linux.dump linux.netstat.Netstat                   # active connections
vol -f linux.dump linux.envars.Envars                     # env vars (LD_PRELOAD = rootkit)
vol -f linux.dump linux.malfind.Malfind                   # RWX hunt
vol -f linux.dump linux.tty_check.tty_check               # TTY hijacking
```

**Hot tip:** `linux.bash.Bash` recovers **all bash sessions** still in memory, even if `~/.bash_history` was wiped. This often catches attackers who deleted history files.

---

## 🍎 macOS equivalents

```bash
vol -f mac.dump mac.pslist.PsList
vol -f mac.dump mac.pstree.PsTree
vol -f mac.dump mac.psaux.Psaux                           # process + args
vol -f mac.dump mac.lsmod.Lsmod                           # kexts
vol -f mac.dump mac.netstat.Netstat
vol -f mac.dump mac.malfind.Malfind
vol -f mac.dump mac.bash.Bash                             # bash history from memory
vol -f mac.dump mac.dmesg.Dmesg                           # kernel ring buffer
vol -f mac.dump mac.kauth_listeners.Kauth_listeners       # security event listeners
vol -f mac.dump mac.kauth_scopes.Kauth_scopes
```

**macOS quirk:** Symbol availability depends heavily on kernel version. Test `mac.info.Info` first to confirm symbols match.

---

## ⚙️ The 30-minute hunt sequence

```bash
#!/bin/bash
SAMPLE=$1
OUT=memory_triage_$(date +%Y%m%d_%H%M%S)
mkdir $OUT && cd $OUT

# Round 1 — orientation (5 min)
vol -f $SAMPLE windows.info.Info > info.txt
vol -f $SAMPLE windows.pstree.PsTree > pstree.txt

# Round 2 — visible state (10 min)
vol -f $SAMPLE windows.cmdline.CmdLine > cmdline.txt
vol -f $SAMPLE windows.netscan.NetScan > netscan.txt
vol -f $SAMPLE windows.svcscan.ScanSvc > services.txt

# Round 3 — the hunting (10 min)
vol -f $SAMPLE windows.malfind.Malfind > malfind.txt
vol -f $SAMPLE windows.psscan.PsScan > psscan.txt
diff <(awk '{print $3}' pstree.txt | sort -u) <(awk '{print $3}' psscan.txt | sort -u) > hidden_procs.txt

# Round 4 — persistence (5 min)
vol -f $SAMPLE windows.registry.hivelist.HiveList > hives.txt
vol -f $SAMPLE windows.registry.printkey.PrintKey \
    --key 'Software\Microsoft\Windows\CurrentVersion\Run' > runkey.txt

ls -la
```

By the end of 30 minutes you have:
- Process tree
- Network state at capture time
- Service inventory
- Injected code regions
- Hidden process candidates (diff)
- Run-key persistence

That's 80% of the value of a memory dump.

---

## 🎯 What memory gives you that disk doesn't

| Evidence | Disk has it? | Memory has it? |
|---|:---:|:---:|
| Process tree at incident time | ❌ (only via Prefetch / Amcache, lossy) | ✅ |
| **Decrypted ransomware payload** | ❌ (encrypted on disk) | ✅ (decrypted at runtime) |
| **Injected code regions** (T1055) | ❌ | ✅ |
| Active network connections | ❌ | ✅ |
| **In-memory only malware** (fileless) | ❌ | ✅ |
| **Mimikatz output / credential blobs** | ❌ | ✅ |
| Loaded but unloaded kernel modules | partial | ✅ |
| Browser session tabs / cookies (open) | partial | ✅ |
| RDP session keys | ❌ | ✅ |

This is why **the volatility-first principle** matters: pull memory before reboot, always.

---

## 📚 References

- **[Volatility 3 docs](https://volatility3.readthedocs.io/en/latest/)** — official, current
- **[volatilityfoundation.org](https://volatilityfoundation.org)** — releases, training, plugin contest
- **Andrew Case (Volatility Foundation)** — primary maintainer; talks at OSDFCon are gold
- **The Art of Memory Forensics** — Ligh, Case, Levy, Walters (Wiley, 2014) — still the best book despite Vol2 examples
- **[FTSCon (From The Source Conference)](https://volatilityfoundation.org)** — 2026 inaugural year, Arlington VA
- **Acquisition tools:**
  - **Magnet RAM Capture** (Windows, free) — fastest acquisition
  - **WinPmem** (Windows, open-source) — for scripted IR
  - **AVML** (Linux, MS open-source) — Microsoft's Linux memory acquirer
  - **`osxpmem`** (macOS, archived) — limited macOS support; consider Magnet AXIOM Cyber for production

---

## ↩️ Back

← [Resources/](../Resources/) · [GitNote root](../README.md)
