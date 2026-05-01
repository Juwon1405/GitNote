# [Resources] DFIR 2026 — Essential Reading

> Reports + research that are actually shaping incident response practice in 2025-2026. Curated, not exhaustive.
>
> **Last updated:** 2026-05-01

---

## 🔴 Annual reports — read when published

### Mandiant M-Trends 2026
- **What:** ~500K hours of frontline IR engagements distilled into trends.
- **Why this year matters:** Confirmed that **recovery denial** (T1490 — vssadmin/wbadmin/bcdedit chains) is the #1 ransomware operational trend. Vishing reached 11% of initial-access vectors (#2 vector after public-facing exploit). Median dwell time keeps shifting based on detection maturity.
- **Where:** [cloud.google.com/security/resources/m-trends](https://cloud.google.com/security/resources/m-trends)

### Verizon DBIR 2026
- **What:** ~9,000 incidents and ~5,000 breaches across all sectors. Statistics-heavy.
- **Why this year matters:** Stolen credentials + social engineering still dominate initial access. Vulnerability exploitation continues climbing.
- **Where:** [verizon.com/business/resources/reports/dbir](https://www.verizon.com/business/resources/reports/dbir/)

### Recorded Future — 2026 Ransomware Tactics
- **What:** Insikt Group's annual threat actor TTP synthesis.
- **Why:** Confirmed insider recruitment trend (ransomware groups recruiting native English speakers from companies undergoing layoffs). Predicted 2026 = first year non-Russian groups outnumber Russian ones.
- **Where:** [recordedfuture.com/blog/ransomware-tactics-2026](https://www.recordedfuture.com/blog/ransomware-tactics-2026)

### CrowdStrike Global Threat Report 2026
- **What:** Adversary intelligence; eCrime + state-sponsored.
- **Why:** Leading source on China-Russia-NK-Iran threat clusters with named TTP catalogs.
- **Where:** [crowdstrike.com/global-threat-report](https://www.crowdstrike.com/) (gated)

### Microsoft Digital Defense Report 2025
- **What:** ~78 trillion daily security signals processed by Microsoft, distilled.
- **Why:** Cloud-attack patterns at scale that smaller vendors don't see.

---

## 🟡 The DFIR Report — case studies (free, hot)

[**The DFIR Report**](https://thedfirreport.com) is the single most useful source for **"how did this attack actually unfold"** style cases. They publish ~monthly with full timelines, IOCs, and Sigma rules.

**Recent (2025-2026) cases worth reading:**

- **2026-02 — SQL Brute Force Leads to BlueSky Ransomware** ([thedfirreport.com](https://thedfirreport.com)) — MS SQL brute force → xp_cmdshell → BlueSky ransomware
- **2025-12 — From OneNote to RansomNote: An Ice Cold Intrusion** — OneNote phishing payload → IcedID → Lockbit
- **2025-11 — Akira Flash Alert** — paired with the CISA AA24-109A advisory
- **2025-09 — DragonForce / Play / RansomHub triangle** — affiliate sharing across RaaS programs
- **2025-06 — RansomHub via RDP** — abuse of leaked credentials → RDP → RansomHub
- **2025-05 — Mimic ransomware via elpacoteam** — multi-stage loader → Mimic encryption
- **2025-04 — Sliver C2 to ransomware** — open-source C2 reaching ransomware deployment

**The DFIR Report Sigma Rules:** [github.com/The-DFIR-Report/Sigma-Rules](https://github.com/The-DFIR-Report/Sigma-Rules) — published rules from each case.

---

## 🟢 Threat actor handbook (top RaaS programs in 2026)

| Group | Active since | Primary targeting | Distinctive TTP |
|---|:---:|---|---|
| **The Gentlemen** ⭐ NEW | mid-2025 | corporate / multi-platform | Multi-OS lockers (Win/Linux/BSD/NAS in Go, ESXi in C). SystemBC for SOCKS5 tunneling. wevtutil + del prefetch + del RDP logs. >320 victims by Q1 2026. |
| **Akira** | 2023 | mid-market | ESXi targeting, double extortion via Tor leak site. CISA AA24-109A. |
| **BlackSuit** (Royal successor) | 2023 | enterprise | Heavy use of legitimate RMM (AnyDesk, Atera). |
| **Lynx** | 2024 | broad | Smaller, faster operations. Affiliate-friendly RaaS. |
| **Fog** | 2024 | education + finance | VPN-first initial access. |
| **Qilin** (Agenda) | 2022 | cross-sector | Rust-based; one of few to consistently target Linux/ESXi from day one. |
| **Lockbit** | 2019 | enterprise | Resurgent post-Operation Cronos. Affiliate-driven RaaS. |
| **DragonForce** | 2024 | broad | Frequently shares affiliates with Play, RansomHub. |
| **Scattered Spider** | 2022 | hospitality + tech | Native English-speaker social engineering specialists. MFA bombing + helpdesk vishing. **NOT a RaaS — direct intrusion crew.** |

---

## 📚 Books worth reading (for senior analysts)

| Title | Author | Why |
|---|---|---|
| **The Practice of Network Security Monitoring** | Richard Bejtlich | The methodology that became modern blue-teaming |
| **Intelligence-Driven Incident Response** | Roberts & Brown | F3EAD applied to IR |
| **The Art of Memory Forensics** | Ligh, Case, Levy, Walters | Still the canonical Volatility text |
| **Incident Response & Computer Forensics, 3rd ed.** | Luttgens, Pepe, Mandia | The canonical IR field manual |
| **Practical Memory Forensics** | Ostrovskaya & Skulkin | Modern (2022) memory-only IR |
| **Incident Response Techniques for Ransomware Attacks** | Skulkin | Ransomware-specific playbook |
| **The Art of Mac Malware vol 1: Persistence** | Patrick Wardle | Free PDF — required for any Mac analyst |
| **Crafting the InfoSec Playbook** | Bollinger, Enright, Valites (Cisco) | SOC operations + playbook authoring |

---

## 🎓 Training that actually moves the needle

| Course | Provider | Track |
|---|---|---|
| **SANS FOR508** — Advanced Incident Response, Threat Hunting and Digital Forensics | SANS | Windows DFIR depth |
| **SANS FOR509** — Enterprise Cloud Forensics & IR | SANS | Cloud-native IR |
| **SANS FOR518** — Mac and iOS Forensic Analysis | SANS | macOS DFIR |
| **SANS FOR532** — Enterprise Memory Forensics In-Depth | SANS | Volatility 3 deep |
| **Volatility Foundation Memory Forensics Training** | Volatility | The maintainers teach it themselves |
| **Mac4n6 with Sarah Edwards** | mac4n6.com | macOS unified log + SQLite forensics |
| **13Cubed (Richard Davis)** | 13Cubed | YouTube + paid courses; hands-on Windows artifact analysis |
| **TCM Security PEH** | TCM Security | Pivot from blue → purple understanding |

---

## 🛠️ Tools published / updated in 2025-2026

| Tool | What's new | Where |
|---|---|---|
| **Volatility 3 v2.27** (Jan 2026) | New plugins + config file support | [github.com/volatilityfoundation/volatility3](https://github.com/volatilityfoundation/volatility3) |
| **Hayabusa** (Yamato Security, Tokyo, third-party) | 4000+ Sigma rules, full Sigma v2 spec, Velociraptor integration | [github.com/Yamato-Security/hayabusa](https://github.com/Yamato-Security/hayabusa) |
| **Velociraptor** | Continued growth as the open-source EDR/IR platform | [github.com/Velocidex/velociraptor](https://github.com/Velocidex/velociraptor) |
| **DFIR-IRIS** | Mature collaborative IR platform | [github.com/dfir-iris/iris-web](https://github.com/dfir-iris/iris-web) |
| **Timesketch** | Continued, used as the industry-standard timeline UI | [github.com/google/timesketch](https://github.com/google/timesketch) |
| **Capa (Mandiant)** | Static malware capability identification | [github.com/mandiant/capa](https://github.com/mandiant/capa) |
| **Eric Zimmerman tools** | MFTECmd, PECmd, AmcacheParser, etc. — continuously updated | [ericzimmerman.github.io](https://ericzimmerman.github.io/) |
| **MasterParser** (SecurityJoes) | Single-binary multi-artifact Windows IR parser | [github.com/securityjoes/MasterParser](https://github.com/securityjoes/MasterParser) |

---

## 📰 Newsletters / blogs to subscribe

- **[The DFIR Report](https://thedfirreport.com)** — monthly case studies (free)
- **[This Week in 4n6](https://thisweekin4n6.com)** — weekly DFIR roundup
- **[mac4n6.com](https://mac4n6.com)** — Sarah Edwards on macOS DFIR
- **[adsecurity.org](https://adsecurity.org)** — Sean Metcalf on AD attacks
- **[objective-see.org](https://objective-see.org)** — Patrick Wardle on Mac malware
- **[volatility-labs.blogspot.com](https://volatility-labs.blogspot.com)** — Volatility Foundation
- **[google.com/security/research](https://cloud.google.com/security/resources)** — Mandiant research
- **[research.checkpoint.com](https://research.checkpoint.com)** — quality threat actor write-ups
- **[Recorded Future Insikt Group](https://www.recordedfuture.com/research)** — strategic CTI

---

## 🎙️ Podcasts (for the commute)

- **Darknet Diaries** — Jack Rhysider — narrative-style
- **The Cyberwire Daily** — David Bittner — daily news
- **Risky Business** — Patrick Gray — weekly news + interviews (Australian, sharp)
- **CISO Series Podcast** — David Spark — CISO perspective
- **Hacking Humans** (CyberWire) — social engineering focus
- **SANS Internet Storm Center StormCast** — daily 5-min from ISC handlers

---

## ⭐ Adjacent must-knows

- **MITRE ATT&CK v16** — the language we all speak. [attack.mitre.org](https://attack.mitre.org)
- **MITRE D3FEND** — defensive countermeasures matrix. [d3fend.mitre.org](https://d3fend.mitre.org)
- **MITRE CAR** — Cyber Analytics Repository. [car.mitre.org](https://car.mitre.org)
- **Atomic Red Team** — TTP test corpus. [atomicredteam.io](https://atomicredteam.io)
- **CISA #StopRansomware** — joint advisories with FBI/NSA. [cisa.gov/stopransomware](https://www.cisa.gov/stopransomware)
- **NIST SP 800-61r2 / 800-86 / 800-150** — foundational US gov DFIR doctrine

---

## ↩️ Back

← [Resources/](../Resources/) · [GitNote root](../README.md)
