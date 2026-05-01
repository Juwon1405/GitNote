<div align="center">

# 📚 GitNote

**A curated knowledge base for Digital Forensics, Incident Response, and Defensive Security**

*Maintained by [Yushin (방주원 / Bang Juwon)](https://github.com/Juwon1405) — DFIR Senior Specialist · Tokyo*

---

[![Last Updated](https://img.shields.io/badge/Last_updated-2026--05--01-blue?style=flat-square)](https://github.com/Juwon1405/GitNote)
[![Resources](https://img.shields.io/badge/IR_frameworks-66_PDFs-red?style=flat-square)]()
[![Stars Curated](https://img.shields.io/badge/Curated_stars-204-yellow?style=flat-square)](Resources/awesome-stars.md)
[![License](https://img.shields.io/badge/License-CC_BY_4.0-green?style=flat-square)]()

</div>

---

## What is GitNote?

GitNote is the index I wish existed when I started in DFIR — a **single, opinionated entry point** to the references I actually use, organized so that someone walking in cold can find what they need in under 60 seconds.

It is **not** an "awesome list" of everything in security. It is a **curated, used-in-practice subset** of:

- 🔍 **Incident response frameworks** — 66 IR/DFIR doctrine PDFs from NIST, SANS, ENISA, KISA, Microsoft, AWS, and more
- 📚 **Resources** — practical guides on phishing analysis, blue team notes, red team tools, mindmaps for tcpdump / Burp / Windows privileges
- 💻 **Code snippets** — working scripts for reverse engineering, macOS setup, network checks
- ⭐ **Curated stars** — [204 GitHub repos categorized into 12 buckets](Resources/awesome-stars.md) (DFIR / Blue Team / AI / Red Team / Malware / OSINT / etc.)

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
│   ├── awesome-stars.md       ⭐ 204 GitHub stars categorized (DFIR/Blue/AI/Red/etc.)
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

## ⚡ Where to start (3 entry points)

### 🥇 If you're a **DFIR practitioner** building an IR program

1. **[NIST SP 800-61 r2 — Computer Security Incident Handling Guide](Repositories/Cyber-Incident-Investigation-Framework/NIST/)** — start here. Foundational.
2. **[NIST SP 800-86 — Guide to Integrating Forensic Techniques into Incident Response](Repositories/Cyber-Incident-Investigation-Framework/NIST/)**
3. **[SANS — Incident Handler's Handbook](Repositories/Cyber-Incident-Investigation-Framework/SANS/)**
4. **[ENISA — Good Practice Guide for Incident Management](Repositories/Cyber-Incident-Investigation-Framework/ENISA/)**

### 🥈 If you're a **Blue Team analyst** building detection coverage

1. **[`[Guide] blue-team-notes.md`](Resources/)** — practical detection pivots
2. **[`[Guide] blue-team-notes_examples-of-lateral-movement.md`](Resources/)** — lateral movement signatures
3. **[`awesome-stars.md` → Blue Team section](Resources/awesome-stars.md)** — 17 SOC/detection-engineering tools
4. **[Mindmap: Windows Privileges](Resources/)** — visual reference for Windows privilege escalation surface

### 🥉 If you're a **Mac/iOS forensic analyst**

1. **[`awesome-stars.md` → macOS section](Resources/awesome-stars.md)** — curated macOS DFIR tools
2. Companion repos by the same author:
   - **[yushin-mac-forensics-platform](https://github.com/Juwon1405/yushin-mac-forensics-platform)** — Flask-based macOS DFIR web platform
   - **[yushin-mac-artifact-collector](https://github.com/Juwon1405/yushin-mac-artifact-collector)** — single-file macOS artifact collector

---

## ⭐ Curated stars — by category

> [**`Resources/awesome-stars.md`**](Resources/awesome-stars.md) — 204 starred GitHub repos, auto-classified into 12 categories with manual review.

| Category | Count |
|---|---:|
| 🔍 DFIR — Forensics & Incident Response | 38 |
| 🤖 AI / LLM / Agentic | 30 |
| 🛡️ Blue Team — SOC, Detection, Threat Hunting | 17 |
| 🦠 Malware Analysis & Reverse Engineering | 15 |
| 📚 Awesome Lists & Curated References | 14 |
| 🌐 OSINT & Threat Intelligence | 14 |
| 🔓 Red Team — Offensive / Pentesting | 13 |
| 🛠️ DevTools & Productivity | 10 |
| 📖 Learning & Career | 7 |
| 🔗 macOS / iOS Security & Forensics | 6 |

---

## 🔗 Companion projects by the same author

| Project | What it is |
|---|---|
| **[agentic-dart](https://github.com/Juwon1405/agentic-dart)** ⭐ | Architecture-first autonomous DFIR agent — SANS FIND EVIL! 2026 submission. 35 typed MCP forensic functions, audit-chained reasoning loop, contradiction handler, 1135-line senior-analyst playbook. |
| **[yushin-gendfir-rag](https://github.com/Juwon1405/yushin-gendfir-rag)** | Unofficial Python replication of *Loumachi, Ghanem & Ferrag — Generative DFIR with RAG* (2024). |
| **[yushin-mac-forensics-platform](https://github.com/Juwon1405/yushin-mac-forensics-platform)** | macOS DFIR forensics platform — Flask-based web tool. |
| **[yushin-mac-artifact-collector](https://github.com/Juwon1405/yushin-mac-artifact-collector)** | Single-file, zero-dependency macOS artifact collector. |

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
