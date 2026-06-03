# 💻 CodeSnippets

Working scripts I've written or adapted for DFIR / reverse engineering / personal productivity. Each file is **self-contained, runnable, and minimal-dependency**.

---

## 🆕 2026 DFIR Triage Scripts — start here

These are the working scripts for current incident response. Each pairs with a cheatsheet in `Resources/`.

### Windows

| Script | What it does | Pairs with |
|---|---|---|
| **[`evtx_quick_triage.py`](./evtx_quick_triage.py)** | Surface suspicious patterns from Windows Security EVTX without Hayabusa or a SIEM. Detects LSASS dumps, brute force bursts, encoded PowerShell, recovery denial, PsExec service installs, NTLM auth for privileged accounts. Self-contained Python (only depends on `python-evtx`). | [`[Cheatsheet] evtx-threat-hunting-2026.md`](../Resources/%5BCheatsheet%5D%20evtx-threat-hunting-2026.md) |
| **[`mft_timestomp_detector.py`](./mft_timestomp_detector.py)** | Detect `$SI < $FN` timestomp anomalies from MFTECmd CSV exports. Surfaces 3 patterns — created predates, modified predates, logical-impossibility. Severity escalates for executables. | [`[Cheatsheet] mft-timestomp-detection.md`](../Resources/%5BCheatsheet%5D%20mft-timestomp-detection.md) |

### macOS

| Script | What it does | Pairs with |
|---|---|---|
| **[`launchd_persistence_audit.sh`](./launchd_persistence_audit.sh)** | Enumerate all 4 launchd locations + per-user LaunchAgents. Surface user-writable plists with `RunAtLoad=true`, plists referencing `/tmp` or `Caches`, system LaunchDaemons NOT owned by root, plists with unsigned or non-Apple binaries. | [`[Cheatsheet] macos-unified-log-triage.md`](../Resources/%5BCheatsheet%5D%20macos-unified-log-triage.md) |
| **[`unified_log_triage.sh`](./unified_log_triage.sh)** | Run the 12 highest-yield Unified Log queries (SSH / sudo / TCC / launchd / Quarantine / XPC / NetworkConfig / XProtect / auth-failures / codesign / ESF / recent-errors). | [`[Cheatsheet] macos-unified-log-triage.md`](../Resources/%5BCheatsheet%5D%20macos-unified-log-triage.md) |

### Linux

| Script | What it does | Pairs with |
|---|---|---|
| **[`auditd_lateral_movement.sh`](./auditd_lateral_movement.sh)** | Search auditd logs for lateral movement signatures (10 categories: SSH key persistence, reverse shells, sudo escalation, network tunnels, pipe-to-shell, LD_PRELOAD, cron/systemd, /etc/passwd changes, history wipe, audit disable). | [`[Cheatsheet] linux-dfir-triage-2026.md`](../Resources/%5BCheatsheet%5D%20linux-dfir-triage-2026.md) |

### Cross-platform

| Script | What it does | Pairs with |
|---|---|---|
| **[`browser_history_carve.py`](./browser_history_carve.py)** | Unified history dump from Chrome / Edge / Firefox / Safari into a single normalized CSV. Read-only (copies DBs to temp). Handles WAL/SHM sidecars. Auto-detects platform. | (general) |
| **[`ioc_sweeper.sh`](./ioc_sweeper.sh)** | Sweep host for hot 2026 IOCs — litellm PyPI supply chain (Mar 2026), polyfill.io (Jun 2024), Python `.pth` cache poisoning, SystemBC / StealBit / Mimikatz signatures, unsanctioned RMM tools (AnyDesk, ScreenConnect, Atera), recovery-denial patterns in shell histories, SSH key persistence, cron / launchd / systemd timer persistence. | [`[Playbook] ransomware-2026-actor-handbook.md`](../Resources/%5BPlaybook%5D%20ransomware-2026-actor-handbook.md) |

---

## 📦 Older snippets (still useful)

### Reverse engineering

| File | What it does |
|---|---|
| `reversing_dump-pyc-with-gdb.md` | Walkthrough technique: dump `.pyc` bytecode from a running Python process using GDB |
| `reversing_dump-pyc-with-gdb_marshal-to-pyc.py` | Helper — marshal-dumped Python code object → valid `.pyc` |
| `reversing_dump-pyc-with-gdb_trymagicnum.py` | Helper — brute-force the right Python magic number |
| `reversing_dump-pyc-with-gdb_py-to-marshal.py` | Helper — `.py` source → marshal format for round-trip testing |

### Setup & utilities

| File | What it does |
|---|---|
| `setup-macos-full-20240204.sh` | Full macOS **GUI workstation** setup (Homebrew + apps + dev/DFIR tools, switches to fish) |
| `setup-macos-headless-terminal-20260603.sh` | **Headless Mac mini (SSH)** zsh terminal glow-up — keeps default zsh, adds starship prompt, fish-style autosuggestions + syntax highlighting, eza/bat/fzf/zoxide/fd/rg/gh/jq/btop/tldr/delta, JetBrainsMono Nerd Font. Idempotent, no `chsh`. |
| `network_checkip.py` | IP enrichment — geo, ASN, abuse score (stdlib only) |
| `LunarToSolarEventCreator.py` | Lunar calendar dates → recurring solar `.ics` events |
| `misc_live-gif-macker.py` | Capture screen region as animated GIF (macOS) |

---

## 🎯 Usage philosophy

These are **small, runnable references** — not packages. Each file:

1. Has a header comment explaining what it does and how to run it
2. Is **stdlib-only** where reasonable; any external dependency is documented at the top
3. Is **kept short** so you can read the entire file before running it
4. Has a working `--help` (Python) or top-of-file usage example (bash)

For larger working projects, see:
- [agentic-dart](https://github.com/Juwon1405/agentic-dart) — autonomous DFIR agent (Python package)
- [yushin-mac-forensics-platform](https://github.com/Juwon1405/yushin-mac-forensics-platform) — macOS DFIR Flask app
- [yushin-mac-artifact-collector](https://github.com/Juwon1405/yushin-mac-artifact-collector) — macOS artifact collector (much more thorough than `unified_log_triage.sh`)

---

## ⚠️ Safety notes

- All scripts are **read-only**. They do not modify files, processes, or registry keys.
- The bash scripts may invoke `sudo` for system path access (clearly indicated). Scripts never call `sudo` themselves — they expect you to run them with `sudo` if needed.
- The Python scripts open SQLite databases via `?mode=ro` and copy to temp before reading to avoid lock contention with live applications (browsers, etc.).
- The `ioc_sweeper.sh` and `auditd_lateral_movement.sh` scripts produce a SHA-256 manifest of all output files for chain-of-custody.

---

## 📜 License

Original snippets are released under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/) unless a file specifies otherwise. Adapted/forked snippets retain their original license.

---

← [Back to GitNote root](../README.md)
