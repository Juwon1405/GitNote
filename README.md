<div align="center">

# 📚 GitNote

**A curated knowledge base for Digital Forensics, Incident Response, and Defensive Security**

*Maintained by [Yushin (방주원 / Bang Juwon)](https://github.com/Juwon1405) — DFIR Senior Specialist · Tokyo*

---

[![Last Updated](https://img.shields.io/badge/Last_updated-2026--05-blue?style=flat-square)](https://github.com/Juwon1405/GitNote)
[![Resources](https://img.shields.io/badge/IR_frameworks-PDFs-red?style=flat-square)]()
[![License](https://img.shields.io/badge/License-CC_BY_4.0-green?style=flat-square)]()

</div>

---

## What is GitNote?

GitNote is the index I wish existed when I started in DFIR — a **single, opinionated entry point** to the references I actually use, organized so that someone walking in cold can find what they need in under 60 seconds.

It is **not** an "awesome list" of everything in security. It is a **curated, used-in-practice subset** of:

- 🔍 **Incident response frameworks** — a curated set of IR/DFIR doctrine PDFs from NIST, SANS, ENISA, KISA, Microsoft, AWS, and more
- 📚 **Resources** — practical guides on phishing analysis, blue team notes, red team tools, mindmaps for tcpdump / Burp / Windows privileges
- 💻 **Code snippets** — working scripts for reverse engineering, macOS setup, network checks
- ⭐ **Curated stars** — [GitHub repos grouped by domain](Resources/awesome-stars.md) (DFIR / Blue Team / AI / Red Team / Malware / OSINT / etc.)

---

## 🗂️ Directory map

```
GitNote/
├── 📂 Repositories/          ← 66 IR/DFIR doctrine PDFs (NIST, SANS, ENISA, KISA…)
│   └── Cyber-Incident-Investigation-Framework/
│       ├── NIST/              (6 PDFs — 800-61, 800-86, 800-150, log mgmt, malware, patch)
│       ├── SANS/              (36 PDFs — incident handling, IR programs, NetWars, etc.)
│       ├── ENISA/             (5 PDFs — EU CSIRT guidance)
│       ├── KISA/              (2 PDFs — Korean IR guides 한국어)
│       ├── Microsoft/         (Microsoft IR Reference Guide)
│       ├── AWS/               (AWS Security Incident Response Guide)
│       ├── ACSC/              (Australian Cyber Security Centre)
│       ├── CREST/             (Cyber Security Incident Response Guide)
│       ├── FCC/               (Computer Security Incident Response Guide)
│       └── …16 organizations total
│
├── 📂 Resources/             ← Working guides + curated indexes
│   ├── awesome-stars.md       ⭐ GitHub stars categorized (DFIR/Blue/AI/Red/etc.)
│   ├── [Guide] blue-team-notes.md
│   ├── [Guide] blue-team-notes_examples-of-lateral-movement.md
│   ├── [Guide] markdown-korean.md
│   ├── [Tips-and-Tricks] phishing-email-analysis.md
│   ├── [Tips-and-Tricks] chatgpt-sheat-sheet.md
│   ├── [Tips-and-Tricks] how-to-copy-github-wiki.md
│   ├── [Resources] red-team-tools.md
│   ├── [Resources] program-analysis.md
│   ├── [Resources] assembly-language.md
│   └── [Mindmap] Tools/        (tcpdump / Burpsuite / Windows Privileges — visual cheatsheets)
│
└── 📂 CodeSnippets/         ← Working scripts (reverse engineering, setup, networking)
    ├── reversing_dump-pyc-with-gdb.md       (RE technique walkthrough)
    ├── reversing_dump-pyc-with-gdb_*.py     (3 helper scripts)
    ├── setup-macos-full-20240204.sh         (full macOS dev/forensics workstation setup)
    ├── LunarToSolarEventCreator.py          (calendar utility)
    ├── network_checkip.py                   (IP enrichment helper)
    └── misc_live-gif-macker.py              (GIF capture tool)
```

---

## ⚡ Where to start (5 entry points)

### 🚨 In an active incident — go here first

| Situation | Read |
|---|---|
| Just got handed a Windows EVTX dump | [`[Cheatsheet] evtx-threat-hunting-2026.md`](Resources/%5BCheatsheet%5D%20evtx-threat-hunting-2026.md) — 12 EIDs that catch 80% of intrusions |
| Suspect ransomware, what group? | [`[Playbook] ransomware-2026-actor-handbook.md`](Resources/%5BPlaybook%5D%20ransomware-2026-actor-handbook.md) — 9 active 2025-2026 RaaS profiles |
| Live macOS host triage | [`[Cheatsheet] macos-unified-log-triage.md`](Resources/%5BCheatsheet%5D%20macos-unified-log-triage.md) + [`launchd_persistence_audit.sh`](CodeSnippets/launchd_persistence_audit.sh) |
| Live Linux host triage | [`[Cheatsheet] linux-dfir-triage-2026.md`](Resources/%5BCheatsheet%5D%20linux-dfir-triage-2026.md) + [`auditd_lateral_movement.sh`](CodeSnippets/auditd_lateral_movement.sh) |
| Memory dump just acquired | [`[Cheatsheet] memory-forensics-vol3.md`](Resources/%5BCheatsheet%5D%20memory-forensics-vol3.md) — Vol3 v2.27 top 12 plugins |
| Suspect AD identity attack | [`[Playbook] identity-attacks-detection.md`](Resources/%5BPlaybook%5D%20identity-attacks-detection.md) — Kerberoasting / Golden Ticket / DCSync etc. |
| Cloud incident (AWS / Entra ID) | [`[Cheatsheet] cloud-dfir-aws-entra.md`](Resources/%5BCheatsheet%5D%20cloud-dfir-aws-entra.md) — top 10 events + queries |
| MFT export, hunt timestomp | [`mft_timestomp_detector.py`](CodeSnippets/mft_timestomp_detector.py) |

### 🥇 If you're a **DFIR practitioner** building an IR program

1. **[`[Resources] dfir-2026-essential-reading.md`](Resources/%5BResources%5D%20dfir-2026-essential-reading.md)** ⭐ — 2026 reading list (M-Trends, DBIR, DFIR Report, books, training)
2. **[NIST SP 800-61 r2](Repositories/Cyber-Incident-Investigation-Framework/NIST/)** — foundational
3. **[NIST SP 800-86](Repositories/Cyber-Incident-Investigation-Framework/NIST/)** — forensic integration
4. **[SANS — Incident Handler's Handbook](Repositories/Cyber-Incident-Investigation-Framework/SANS/)**

### 🥈 If you're a **Blue Team analyst** building detection coverage

1. **[`[Cheatsheet] evtx-threat-hunting-2026.md`](Resources/%5BCheatsheet%5D%20evtx-threat-hunting-2026.md)** — Sigma rules + Hayabusa one-liners
2. **[`[Playbook] identity-attacks-detection.md`](Resources/%5BPlaybook%5D%20identity-attacks-detection.md)** — AD + Entra ID detection signatures
3. **[`awesome-stars.md` → Blue Team section](Resources/awesome-stars.md)** — 17 SOC/detection-engineering tools

### 🥉 If you're a **Mac/iOS forensic analyst**

1. **[`[Cheatsheet] macos-unified-log-triage.md`](Resources/%5BCheatsheet%5D%20macos-unified-log-triage.md)** — 12 working `log show` predicates
2. **[`launchd_persistence_audit.sh`](CodeSnippets/launchd_persistence_audit.sh)** — comprehensive launchd persistence inventory
3. Companion repos by the same author:
   - **[yushin-mac-forensics-platform](https://github.com/Juwon1405/yushin-mac-forensics-platform)** — Flask-based macOS DFIR platform
   - **[yushin-mac-artifact-collector](https://github.com/Juwon1405/yushin-mac-artifact-collector)** — single-file macOS artifact collector

### ☁️ If you're a **Cloud DFIR analyst**

1. **[`[Cheatsheet] cloud-dfir-aws-entra.md`](Resources/%5BCheatsheet%5D%20cloud-dfir-aws-entra.md)** — AWS CloudTrail + Entra ID signatures
2. **[`[Playbook] identity-attacks-detection.md`](Resources/%5BPlaybook%5D%20identity-attacks-detection.md)** — modern Entra ID attacks (device code, PRT theft, MFA fatigue)

---

## ⭐ Curated stars — by category

> [**`Resources/awesome-stars.md`**](Resources/awesome-stars.md) — starred GitHub repos grouped into the categories below. The list is curated and re-organized periodically; exact counts shift with each pass.

- 🔍 DFIR — Forensics & Incident Response
- 🛡️ Blue Team — SOC, Detection, Threat Hunting
- 🦠 Malware Analysis & Reverse Engineering
- 🍎 macOS / iOS Security & Forensics
- 🪟 Windows DFIR
- 🔓 Red Team — Offensive / Pentesting
- 🌐 OSINT & Threat Intelligence
- 🤖 AI / LLM / Agentic
- 📚 Awesome Lists & Curated References
- 📖 Learning & Career
- 🛠️ DevTools & Productivity
- 🇰🇷 Korean Resources

---

## 🔗 Companion projects by the same author

| Project | What it is |
|---|---|
| **[agentic-dart](https://github.com/Juwon1405/agentic-dart)** ⭐ | Architecture-first autonomous DFIR agent — SANS FIND EVIL! 2026 submission. 67 typed MCP forensic functions (incl. cross-platform supply-chain IOC sweeps), audit-chained reasoning loop, contradiction handler, 1182-line senior-analyst playbook. |
| **[agentic-dart-collector-adapter](https://github.com/Juwon1405/agentic-dart-collector-adapter)** *(new — Phase 1.3)* | Stdlib-only Python adapter that turns Velociraptor offline-collector ZIPs into the `evidence_root` layout Agentic-DART consumes. Seeds chain-of-custody (manifest.json + SHA-256 index). |
| **[yushin-mac-artifact-collector](https://github.com/Juwon1405/yushin-mac-artifact-collector)** *(archived)* | Single-file, zero-dependency macOS artifact collector. Originator of the supply-chain IOC sweep now ported into `agentic-dart` as cross-platform MCP functions. |
| **[yushin-mac-forensics-platform](https://github.com/Juwon1405/yushin-mac-forensics-platform)** *(archived)* | macOS DFIR forensics platform — Flask-based web tool. Paused for post-SANS repositioning as the Agentic-DART web UI. |
| **[yushin-gendfir-rag](https://github.com/Juwon1405/yushin-gendfir-rag)** *(archived)* | Unofficial Python replication of *Loumachi, Ghanem & Ferrag — Generative DFIR with RAG* (2024). Superseded by `agentic-dart`. |

---

## 🤝 About the author

**Yushin** (방주원 / バン ジュウォン / 優心) is a DFIR Senior Specialist based in Tokyo, focused on autonomous security operations, agentic DFIR, and macOS forensics. The Japanese reading 優心 means "discerning mind" — the trait this knowledge base is meant to help cultivate.

- 🔗 GitHub: [@Juwon1405](https://github.com/Juwon1405)
- 🌍 Location: Tokyo, Japan
- 🎓 Domain: DFIR · Detection Engineering · Incident Response · macOS Forensics

---

## 📜 License

Documents in `Repositories/` retain their original licenses (NIST/SANS/ENISA/etc. publications are public domain or under their respective publisher terms). Original content (`Resources/`, `CodeSnippets/`, this README) is offered under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/) unless otherwise specified within a file.

If a referenced PDF here belongs to you and you'd like it removed or re-attributed, please open an issue.

---

<div align="center">

*Last updated: 2026-05-01 · Curated by [Yushin](https://github.com/Juwon1405) · Made in Tokyo 🗼*

</div>
