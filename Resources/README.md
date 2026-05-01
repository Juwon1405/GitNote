# 📚 Resources

Practical guides, cheatsheets, playbooks, and curated indexes I actually use in DFIR / blue team / SOC work. Unlike `Repositories/` which is published-by-someone-else doctrine, **the content here is my own notes and curation**.

---

## 🆕 2026 Cheatsheets — start here

These are the working references I built for current threat work. Each is a single self-contained markdown file you can `Ctrl+F` during an active case.

| Cheatsheet | Topic | When you need it |
|---|---|---|
| **[`[Cheatsheet] evtx-threat-hunting-2026.md`](./%5BCheatsheet%5D%20evtx-threat-hunting-2026.md)** | Windows EVTX threat hunting | Walking into a Windows IR case, need to know which 12 EIDs catch 80% of attacks + Hayabusa one-liners |
| **[`[Cheatsheet] mft-timestomp-detection.md`](./%5BCheatsheet%5D%20mft-timestomp-detection.md)** | T1070.006 timestomp detection | MFT is parsed, need to find adversary anti-forensics. The `$SI` < `$FN` logic explained. |
| **[`[Cheatsheet] memory-forensics-vol3.md`](./%5BCheatsheet%5D%20memory-forensics-vol3.md)** | Volatility 3 v2.27 IR triage | Just acquired a memory dump. Top 12 plugins for Win/Linux/macOS. 30-minute hunt sequence. |
| **[`[Cheatsheet] macos-unified-log-triage.md`](./%5BCheatsheet%5D%20macos-unified-log-triage.md)** | macOS unified log queries | Live macOS host or `.logarchive` to triage. 12 working `log show` predicates + 30-min triage script. |
| **[`[Cheatsheet] linux-dfir-triage-2026.md`](./%5BCheatsheet%5D%20linux-dfir-triage-2026.md)** | Linux IR (auditd + journald) | Linux host triage, the 8 highest-yield artifacts + 30-min collection script. 2026 LOLBin patterns. |
| **[`[Cheatsheet] cloud-dfir-aws-entra.md`](./%5BCheatsheet%5D%20cloud-dfir-aws-entra.md)** | Cloud IR — AWS + Entra ID | Cloud-native incident — top 10 CloudTrail events, top 10 Entra ID attack signatures, ready-to-use Athena/KQL queries |

## 🎭 Playbooks — adversary-aware response

| Playbook | What it covers |
|---|---|
| **[`[Playbook] ransomware-2026-actor-handbook.md`](./%5BPlaybook%5D%20ransomware-2026-actor-handbook.md)** | Profiles for the 9 ransomware groups actually active in 2025-2026 (The Gentlemen / Akira / BlackSuit / Lynx / Fog / Qilin / Lockbit / Scattered Spider / DragonForce-Play-RansomHub triangle). Identification → TTPs → defender response. |
| **[`[Playbook] identity-attacks-detection.md`](./%5BPlaybook%5D%20identity-attacks-detection.md)** | The 8 AD identity attacks (Kerberoasting / AS-REP / PtH / PtT / Golden Ticket / Silver Ticket / DCSync / DPAPI) + 4 Entra ID modern equivalents (Device Code phishing / PRT theft / MFA fatigue / token theft). Sigma + KQL detection signatures included. |

## 📖 Reference indexes

| File | Topic |
|---|---|
| **[`[Resources] dfir-2026-essential-reading.md`](./%5BResources%5D%20dfir-2026-essential-reading.md)** ⭐ | The 2026 DFIR reading list — annual reports (M-Trends, DBIR, Recorded Future), case studies, books, training, blogs, podcasts, tools |
| **[`awesome-stars.md`](./awesome-stars.md)** ⭐ | **204 GitHub repos I've starred, categorized into 12 buckets** (DFIR / Blue Team / AI / Red Team / Malware / OSINT / etc.). Auto-classified, manually reviewed. |

---

## 📖 Older guides (still useful)

| File | Topic |
|---|---|
| `[Guide] blue-team-notes.md` | Blue team detection pivots — turning observations into pivots |
| `[Guide] blue-team-notes_examples-of-lateral-movement.md` | Concrete examples of lateral movement detection in Windows |
| `[Guide] markdown-korean.md` | Markdown writing tips for Korean technical authors (한국어 마크다운 작성 가이드) |
| `[Tips-and-Tricks] phishing-email-analysis.md` | Phishing email triage workflow |
| `[Tips-and-Tricks] chatgpt-sheat-sheet.md` | LLM prompt patterns for security work |
| `[Tips-and-Tricks] how-to-copy-github-wiki.md` | How to clone, mirror, or import a GitHub wiki repo |
| `[Resources] red-team-tools.md` | Annotated index of offensive tooling |
| `[Resources] program-analysis.md` | Program analysis primer — static, dynamic, symbolic |
| `[Resources] assembly-language.md` | x86_64 / ARM64 assembly references |

## 🧠 Mindmaps (visual cheatsheets)

In **`[Mindmap] Tools/`**:

| Tool | Files |
|---|---|
| **Tcpdump** | PDF + 3 image resolutions (Normal / HD / UHD) |
| **Burpsuite** | Single-page reference image |
| **Windows Privileges** | PDF + 3 image resolutions |

---

## 🥇 If you only read three things

1. **[`[Resources] dfir-2026-essential-reading.md`](./%5BResources%5D%20dfir-2026-essential-reading.md)** — the meta-index of what to read in 2026
2. **[`[Cheatsheet] evtx-threat-hunting-2026.md`](./%5BCheatsheet%5D%20evtx-threat-hunting-2026.md)** — the 12 EIDs that catch 80% of intrusions
3. **[`[Playbook] ransomware-2026-actor-handbook.md`](./%5BPlaybook%5D%20ransomware-2026-actor-handbook.md)** — actor TTP profiles for the groups actually active

---

## 📝 Filename conventions

| Prefix | Meaning |
|---|---|
| `[Cheatsheet] *` | Tactical, single-domain, Ctrl+F-able reference for live cases |
| `[Playbook] *` | Multi-step response procedure for a class of incidents |
| `[Guide] *` | Long-form how-to or methodology document |
| `[Tips-and-Tricks] *` | Short, tactical, single-topic tip |
| `[Resources] *` | Curated index of external resources on a topic |
| `[Mindmap] *` | Visual / diagrammatic reference |

---

## 🔄 How this directory evolves

- **Cheatsheets** are versioned by year (`-2026.md`). When 2027 comes, I add `-2027.md` rather than overwriting (so you can always see what was current when).
- **Playbooks** evolve as ransomware groups come and go. Annual major refresh.
- **`awesome-stars.md`** regenerates periodically (~monthly) from my live GitHub starred list.
- **Older guides** (without year suffix) are stable; I only update them when something fundamental changes.

---

← [Back to GitNote root](../README.md)
