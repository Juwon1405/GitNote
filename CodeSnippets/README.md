# 💻 CodeSnippets

Working scripts I've written or adapted for DFIR / reverse engineering / personal productivity. Each file is **self-contained, runnable, and minimal-dependency**.

---

## 🗂️ Contents

### 🔬 Reverse engineering

| File | What it does |
|---|---|
| **[`reversing_dump-pyc-with-gdb.md`](reversing_dump-pyc-with-gdb.md)** ⭐ | Walkthrough technique: dump `.pyc` bytecode from a running Python process using GDB. Useful when malware ships compiled-only Python and you can attach to a running process. |
| **[`reversing_dump-pyc-with-gdb_marshal-to-pyc.py`](reversing_dump-pyc-with-gdb_marshal-to-pyc.py)** | Helper — converts a `marshal`-dumped Python code object back into a valid `.pyc` file with the right magic header. |
| **[`reversing_dump-pyc-with-gdb_trymagicnum.py`](reversing_dump-pyc-with-gdb_trymagicnum.py)** | Helper — brute-forces the right Python magic number when the version is unknown. |
| **[`reversing_dump-pyc-with-gdb_py-to-marshal.py`](reversing_dump-pyc-with-gdb_py-to-marshal.py)** | Helper — converts an extracted `.py` source back to marshal format for round-trip testing. |

### 🛠️ Setup & tooling

| File | What it does |
|---|---|
| **[`setup-macos-full-20240204.sh`](setup-macos-full-20240204.sh)** | Full macOS workstation setup — Homebrew packages, dev tools, DFIR tools, dotfiles. Dated to lock the snapshot (run on a fresh macOS 14 install). |

### 🌐 Networking

| File | What it does |
|---|---|
| **[`network_checkip.py`](network_checkip.py)** | Quick IP enrichment — geo-location, ASN, abuse score. Single-file, stdlib-only. |

### 🛠️ Misc utilities

| File | What it does |
|---|---|
| **[`LunarToSolarEventCreator.py`](LunarToSolarEventCreator.py)** | Convert lunar calendar dates (Korean / Chinese / Vietnamese cultural dates) into recurring solar-calendar `.ics` calendar events. |
| **[`misc_live-gif-macker.py`](misc_live-gif-macker.py)** | Capture a screen region as an animated GIF on macOS. Quick demos / bug repro. |

---

## 🎯 How to use these

These are **small, runnable references** — not packages. Each file:

1. Has a header comment explaining what it does and how to run it
2. Is **stdlib-only** where reasonable; any external dependency is documented at the top
3. Is **kept short** so you can read the entire file before running it

For larger working projects, see:
- [agentic-dart](https://github.com/Juwon1405/agentic-dart) — autonomous DFIR agent (Python package)
- [yushin-mac-forensics-platform](https://github.com/Juwon1405/yushin-mac-forensics-platform) — macOS DFIR Flask app
- [yushin-mac-artifact-collector](https://github.com/Juwon1405/yushin-mac-artifact-collector) — macOS artifact collector

---

## 📜 License

Original snippets are released under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/) unless a file specifies otherwise. Adapted/forked snippets retain their original license.

---

← [Back to GitNote root](../README.md)
