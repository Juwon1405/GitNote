# [Playbook] 2026 Ransomware Actor Handbook

> Concise TTP profiles for the ransomware groups actually active in 2025-2026. Sourced from The DFIR Report, CISA #StopRansomware advisories, Check Point Research, Mandiant M-Trends 2026, and Recorded Future Insikt Group reports.
>
> **Last updated:** 2026-05-01

---

## 🎯 Why this handbook exists

When you walk into an active ransomware case, **the question is rarely "what is ransomware"**. It's **"which group is this and what do they do next?"** This handbook is the cheat sheet for that triage moment.

Each profile follows a fixed structure: identification signals → initial access → persistence → lateral movement → impact → defender-relevant pivots.

---

## 1️⃣ The Gentlemen ⭐ (NEW 2025)

**Identification:** Multi-OS lockers (Go for Windows/Linux/BSD/NAS; C for ESXi). Tor leak site + Twitter/X account. >320 victims by Q1 2026, with 240 in early 2026 alone.

| Phase | TTP |
|---|---|
| **Initial Access** | VPN credential theft, Bomgar RMM exploitation (CVE-2026-1731), public-facing app exploitation |
| **Execution** | SystemBC for SOCKS5 tunneling (RC4-encrypted custom protocol); Mimikatz; RPC for remote execution |
| **Persistence** | Multi-OS — service install (Windows), systemd unit (Linux), launchd (BSD), tradition kernel modules |
| **Privilege Escalation** | Mimikatz LSASS dump → DC compromise |
| **Defense Evasion** | `wevtutil cl System / Application / Security`, `del /f /q C:\Windows\Prefetch\*.*`, `del /f /q C:\ProgramData\Microsoft\Windows Defender\Support\*.*`, `del /f /q %SystemRoot%\System32\LogFiles\RDP*\*.*` |
| **Impact** | `--wipe` flag overwrites free disk space (64MB chunks until exhausted); shadow copy delete; encryption |

**Defender pivot:** `wevtutil cl` execution = treat as **active ransomware deployment**, not noise. By the time these run, encryption is starting.

> 📖 **심층 분석 (한글):** 조직 구조 · 도구 체계 · 메신저(TOX) · 자금 세탁 · AI 활용까지 다룬 행위 중심 핸드북 → [`[Playbook] The Gentlemen RaaS — 심층 행위분석 핸드북`](%5BPlaybook%5D%20gentlemen-raas-deep-dive-ko.md)

**Reference:** [Check Point Research — DFIR Report: The Gentlemen & SystemBC](https://research.checkpoint.com/2026/dfir-report-the-gentlemen/) · [Thus Spoke the Gentlemen (2026)](https://research.checkpoint.com/2026/thus-spoke-the-gentlemen/)

---

## 2️⃣ Akira

**Identification:** Tor leak site at `akiral2iz6a7qgd3ayp3l6yub7xx2uep76idk3u2kollpj5z3z636bad.onion`. Heavy ESXi targeting. CISA AA24-109A advisory (Nov 2025).

| Phase | TTP |
|---|---|
| **Initial Access** | Cisco ASA/FTD VPN exploitation (CVE-2023-20269), VPN credential phishing |
| **Execution** | Mimikatz, Impacket, AnyDesk for persistence |
| **Persistence** | Domain admin account creation, Group Policy modifications, RMM tool installation |
| **Lateral Movement** | RDP, WMI, AdFind for AD recon |
| **Defense Evasion** | Disabling AV via PowerShell; clearing event logs |
| **Impact** | ESXi locker bricks the entire virtualization plane; double extortion via Tor |

**Defender pivot:** Cisco VPN log review for unusual login geographies + `aaa-server` config changes in the days prior.

**Reference:** [CISA AA24-109A](https://www.cisa.gov/news-events/cybersecurity-advisories), [The DFIR Report — Akira Flash Alert (Nov 2025)](https://thedfirreport.com)

---

## 3️⃣ BlackSuit (Royal successor)

**Identification:** Royal ransomware re-branded after operational disruption. Heavy use of legitimate IT tools.

| Phase | TTP |
|---|---|
| **Initial Access** | Phishing (callback phishing common), VPN credential abuse |
| **Execution** | Cobalt Strike, AnyDesk, Atera for legitimate-looking persistence |
| **Persistence** | Domain admin creation, scheduled tasks, RMM tool drops |
| **Lateral Movement** | RDP heavily; SMB; Cobalt Strike beacons |
| **Defense Evasion** | GMER/PowerTool to disable AV; event log clearing |
| **Impact** | `vssadmin delete shadows`; `wbadmin delete catalog`; encryption with `.blacksuit` extension |

**Defender pivot:** AnyDesk + Atera installations on hosts where you have no IT change ticket = treat as adversary action.

---

## 4️⃣ Lynx (2024)

**Identification:** "Cat's Got Your Files" branding. Affiliate-friendly RaaS. Modest sophistication.

| Phase | TTP |
|---|---|
| **Initial Access** | Stolen credentials from IABs (Initial Access Brokers); phishing |
| **Execution** | PowerShell + LotL; occasional Cobalt Strike |
| **Persistence** | Service install, scheduled task, registry Run keys |
| **Defense Evasion** | Disable AMSI via reflection; clear PowerShell history |
| **Impact** | Encryption + leak site posting |

**Defender pivot:** Watch for AMSI-disabling reflective PowerShell — unique-ish signature.

---

## 5️⃣ Fog (2024)

**Identification:** Education + finance vertical focus. VPN-first.

| Phase | TTP |
|---|---|
| **Initial Access** | VPN credential theft (often from infostealer logs) |
| **Execution** | RDP for hands-on-keyboard work; Mimikatz |
| **Persistence** | Local admin creation + RDP enablement |
| **Lateral Movement** | RDP exclusively in many cases — almost no Cobalt Strike |
| **Defense Evasion** | Manual log clearing; AV disable via UI |
| **Impact** | Fast — sometimes <12 hours from entry to encryption |

**Defender pivot:** Education sector + sudden VPN logins from new geos + RDP enable on multiple hosts within hours = match this profile.

**Reference:** [The DFIR Report — Navigating Through The Fog](https://thedfirreport.com)

---

## 6️⃣ Qilin (Agenda)

**Identification:** Rust-based locker. Multi-OS from day one (Linux/ESXi natives, not afterthought). Aggressive in 2025-2026.

| Phase | TTP |
|---|---|
| **Initial Access** | Phishing, exposed credentials, vulnerability exploitation |
| **Execution** | Custom Rust loader; PowerShell; ESXi shell |
| **Persistence** | Cross-platform — service install on Windows, systemd unit on Linux, init script on ESXi |
| **Lateral Movement** | RDP + SSH + ESXi shell |
| **Defense Evasion** | `vssadmin`, `wevtutil cl`, ESXi log deletion |
| **Impact** | Multi-OS encryption; some affiliates disable backup infrastructure first |

**Defender pivot:** ESXi login from non-admin source IP + `vmkfstools` activity outside change windows = active Qilin-pattern.

---

## 7️⃣ Lockbit (post-Operation Cronos)

**Identification:** Resurgent after Feb 2024 disruption. Affiliate-driven RaaS — wide variance in actual TTPs.

| Phase | TTP |
|---|---|
| **Initial Access** | Variable — affiliate dependent. Phishing, RMM compromise, VPN cred theft |
| **Execution** | Cobalt Strike (most affiliates), occasionally Sliver |
| **Persistence** | Affiliate-dependent |
| **Lateral Movement** | RDP, WMI, PsExec |
| **Defense Evasion** | Built-in StealBit data exfil tool; multi-mode locker |
| **Impact** | Encryption with `.lockbit` extensions; double extortion |

**Defender pivot:** **StealBit binary detection** is high-confidence Lockbit signal.

---

## 8️⃣ Scattered Spider ⚠️ (NOT a RaaS — direct intrusion)

**Identification:** Hospitality + tech sector. Native English-speaker social engineering. Helpdesk-call-and-MFA-bomb specialty.

| Phase | TTP |
|---|---|
| **Initial Access** | **Helpdesk vishing** — call IT impersonating an employee, get password reset; **MFA bombing** to force user to approve push |
| **Execution** | Living-off-the-land; legitimate RMM (TeamViewer, AnyDesk); abuse AD admin tools |
| **Persistence** | Compromised SSO + privileged role assignment in Entra ID |
| **Lateral Movement** | OAuth token replay, SAML manipulation, AD abuse |
| **Defense Evasion** | Operate during business hours pretending to be IT; masterful at blending in |
| **Impact** | Often ALPHV/BlackCat or RansomHub deployment; sometimes data theft only without encryption |

**Defender pivot:** Help desk **must** verify identity through a separate channel for password resets. MFA push notifications outside expected work hours = investigate.

**Reference:** Mandiant calls this UNC3944. Microsoft tracks as Octo Tempest.

---

## 9️⃣ DragonForce / Play / RansomHub (affiliate triangle)

**Identification:** Same affiliates often pivot between these three RaaS programs. TTPs converge.

| Phase | Common TTP |
|---|---|
| **Initial Access** | Compromised RMM (ConnectWise ScreenConnect CVE-2024-1709 was watershed); RDP brute force |
| **Execution** | Cobalt Strike + occasional Sliver |
| **Lateral Movement** | RDP / WMI / PsExec |
| **Impact** | RansomHub locker / Play locker / DragonForce locker — choose your branding |

**Defender pivot:** ScreenConnect access logs are a goldmine. Check for unauthorized RMM tool installs.

**Reference:** [The DFIR Report — DragonForce / Play / RansomHub combined case (Sep 2025)](https://thedfirreport.com)

---

## 🚨 Universal recovery-denial signatures (M-Trends 2026 #1 trend)

Regardless of which group, watch for **these commands in T-1h before encryption**:

```powershell
vssadmin delete shadows /all /quiet
wbadmin delete catalog -quiet
bcdedit /set {default} bootstatuspolicy ignoreallfailures
bcdedit /set {default} recoveryenabled No
wevtutil cl Application
wevtutil cl Security
wevtutil cl System
wevtutil cl Setup
fsutil usn deletejournal /D C:
del /f /q %SystemRoot%\System32\LogFiles\*.*
del /f /q C:\Windows\Prefetch\*.*

# Backup infra targeting
nltest /domain_trusts
net group "Domain Admins" /domain
```

If you see ANY of the bottom 9 lines on a host: **assume encryption is imminent**. Containment goes live now, not after the encryption noise.

---

## 🎯 Defender priorities by group profile

| If you see... | Suspect... | Priority action |
|---|---|---|
| ESXi locker + multi-OS | The Gentlemen, Qilin, Akira | Isolate vCenter immediately |
| Helpdesk vishing reports | Scattered Spider | Force password reset for affected user via separate verified channel |
| AnyDesk/Atera unsanctioned | BlackSuit, RansomHub affiliates | Block RMM domains at egress; audit all RMM tool installs in last 14d |
| StealBit binary | Lockbit | Contain laterally — exfil already started |
| OneNote phishing | Older but resurgent — IcedID/Lockbit chains | Block OneNote attachments at gateway; hunt IcedID DLL signatures |
| MS SQL xp_cmdshell + brute force | BlueSky | Disable xp_cmdshell company-wide post-IR; audit SQL accounts |
| `wevtutil cl` + `del prefetch` | Active ransomware deployment | Encryption is starting NOW |

---

## 📚 References

- **[CISA #StopRansomware](https://www.cisa.gov/stopransomware)** — joint advisories with FBI/NSA
- **[The DFIR Report](https://thedfirreport.com)** — case-by-case TTP write-ups
- **[Mandiant M-Trends 2026](https://cloud.google.com/security/resources/m-trends)** — recovery denial #1 trend
- **[Recorded Future 2026 Ransomware Tactics](https://www.recordedfuture.com/blog/ransomware-tactics-2026)** — insider recruitment, RaaS bundling
- **[Check Point Research — The Gentlemen](https://research.checkpoint.com/2026/dfir-report-the-gentlemen/)**

---

## ↩️ Back

← [Resources/](../Resources/) · [GitNote root](../README.md)
