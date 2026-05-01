# 📁 Repositories — Cyber Incident Investigation Framework

A curated archive of **66 incident response and digital forensics doctrine documents** from 16 international organizations. These are the published-by-someone-else references that I rely on when designing IR programs, training analysts, or arguing for a specific procedural choice.

> **Why this archive exists.** Because finding the *right* IR doctrine PDF in 2026 means clicking through five "join our newsletter" walls on five different vendor sites, and half the links are dead. Here they are, indexed.

---

## 📊 By organization

| Organization | Count | Region | Coverage |
|---|---:|---|---|
| **SANS Institute** | 36 | 🇺🇸 | Incident handling, IR programs, forensics, training, IH-as-a-service |
| **NIST** | 6 | 🇺🇸 | SP 800-61 r2, SP 800-86, SP 800-150, log mgmt, malware, patch mgmt |
| **ENISA** | 5 | 🇪🇺 | EU CSIRT/CERT good-practice guidance |
| **KISA** | 2 | 🇰🇷 | 한국 침해사고 분석 절차 / 민간부분 침해사고 대응 |
| **ACSC** | 1 | 🇦🇺 | Strategies to Mitigate Cyber Security Incidents |
| **APPA** | 1 | 🇺🇸 | Public Power Cyber Incident Response Playbook |
| **AWS** | 1 | 🌐 | AWS Security Incident Response Guide |
| **CAL-CSIC** | 1 | 🇺🇸 | California Joint Cyber Incident Response Guide |
| **CREST** | 1 | 🇬🇧 | Cyber Security Incident Response Guide |
| **Cyber Security Coalition** | 1 | 🇧🇪 | Cyber Security Incident Management Guide |
| **FCC** | 1 | 🇺🇸 | Computer Security Incident Response Guide |
| **FSB** | 1 | 🌐 | Effective Practices for Cyber Incident Response and Recovery |
| **GCSB** | 1 | 🇳🇿 | New Zealand Security Incident Management Guide |
| **IIROC** | 1 | 🇨🇦 | Cyber Incident Management Planning Guide |
| **Kaspersky** | 1 | 🇷🇺 | (vendor IR guide) |
| **KR_FSEC** | 1 | 🇰🇷 | (한국 금융보안원 자료) |
| **Microsoft** | 1 | 🌐 | Incident Response Reference Guide |
| **US-CERT** | 1 | 🇺🇸 | Incident Management |
| **TOTAL** | **66** | — | — |

---

## 🥇 Read these first (essential 5)

If you're new to IR or building a program from scratch:

1. **[NIST SP 800-61 r2 — Computer Security Incident Handling Guide](Cyber-Incident-Investigation-Framework/NIST/)** ⭐
   The foundational framework. PICERL phases (Preparation → Identification → Containment → Eradication → Recovery → Lessons learned). If you read one, read this.

2. **[NIST SP 800-86 — Guide to Integrating Forensic Techniques into Incident Response](Cyber-Incident-Investigation-Framework/NIST/)** ⭐
   How forensics actually fits inside the IR loop. Order of volatility, chain of custody, evidence handling.

3. **[SANS — Incident Handler's Handbook](Cyber-Incident-Investigation-Framework/SANS/)** ⭐
   Patrick Kral's classic. PICERL applied with realistic scenarios.

4. **[ENISA — Good Practice Guide for Incident Management](Cyber-Incident-Investigation-Framework/ENISA/)** ⭐
   EU perspective. Strong on cross-border coordination + CSIRT operations.

5. **[Microsoft — Incident Response Reference Guide](Cyber-Incident-Investigation-Framework/Microsoft/)** ⭐
   Vendor-neutral despite the source. Pragmatic over doctrinal.

---

## 📚 By topic

### Incident response **fundamentals**
- NIST SP 800-61 r2 (Computer Security Incident Handling Guide)
- SANS — Incident Handler's Handbook
- SANS — An Incident Handling Process for Small and Medium Businesses
- SANS — Building an Incident Response Program To Suit Your Business
- SANS — Creating and Managing an Incident Response Team for a Large Company
- ENISA — Good Practice Guide for Incident Management

### **Forensics integration** with IR
- NIST SP 800-86 (Forensic Techniques into IR)
- SANS — Computer Forensics: Introduction to IR and Investigation of Windows NT/2000
- SANS — Pros and Cons of using Linux and Windows Live CDs in Incident Handling and Forensics
- SANS — Enhancing IR through forensic, memory analysis and malware sandboxing techniques
- SANS — A Guide to Encrypted Storage Incident Handling

### **Cloud + scaled** environments
- AWS — Security Incident Response Guide
- SANS — Following Incidents into the Cloud
- SANS — Incident Handling in the Healthcare Cloud

### **Malware, ransomware, zero-day**
- NIST SP 800-83 r1 (Guide to Malware Incident Prevention and Handling for Desktops and Laptops)
- SANS — Responding to Zero Day Threats
- SANS — Multi-Tool DVD Sets for the Incident Handler/Pen Tester's toolkit
- KR_FSEC (Korean Financial Security)

### **Detection / monitoring** integration
- SANS — Event Monitoring and Incident Response
- SANS — Incident Response in a Security Operation Center
- NIST SP 800-92 (Guide to Computer Security Log Management)
- NIST SP 800-150 (Guide to Cyber Threat Information Sharing — referenced indirectly)
- NIST SP 800-40 r3 (Patch and Vulnerability Management Program)

### **Sector-specific**
- APPA — Public Power Cyber Incident Response Playbook
- IIROC — Cyber Incident Management Planning Guide (financial)
- FSB — Effective Practices for Cyber Incident Response and Recovery (financial stability)
- CAL-CSIC — California Joint Cyber Incident Response Guide (state government)

### **National / regional doctrine**
- KISA — 침해사고 분석절차 안내서 (Korea)
- KISA — 민간부분 침해사고 대응 안내서 (Korea)
- ACSC — Strategies to Mitigate Cyber Security Incidents (Australia)
- GCSB — New Zealand Security Incident Management Guide for CSIRTs
- ENISA — Good Practice Guide (EU)
- Cyber Security Coalition (Belgium) — Incident Management Guide
- FCC — Computer Security Incident Response Guide (USA)
- CREST — Cyber Security Incident Response Guide (UK)

### **Tabletop / training / scaling**
- SANS — Incident Handling Annual Testing and Training
- SANS — Incident Handling Preparation: Learning Normal with the Kansa PowerShell IR Framework
- SANS — Incident Handling as a Service
- SANS — Quick and Effective Windows System Baselining and Comparative Analysis
- SANS — Baselines and Incident Handling

### **Specialized situations**
- SANS — Security Incident Handling in High Availability Environments
- SANS — Breach Notification in Incident Handling
- SANS — Security Incident Handling in Small Organizations
- SANS — Incident Tracking In The Enterprise
- SANS — Psychology and the hacker — Psychological Incident Handling
- SANS — Mining gold... A primer on incident handling and response
- SANS — Expanding Response: Deeper Analysis for Incident Handlers
- SANS — CodeRed II Incident Handling Process and Procedures (historical)

---

## 🛠️ How to use this archive

For an IR program lead:
1. Read NIST SP 800-61 r2 cover-to-cover. That's your skeleton.
2. Then SP 800-86 for the forensics layer.
3. Then your sector reference (APPA / IIROC / FSB / sector-specific).
4. Then ENISA or CREST for cross-border coordination protocols.
5. Then the SANS papers as case-by-case enrichment.

For an analyst:
1. Start with the Incident Handler's Handbook (SANS).
2. Pivot to the technical SANS papers as you encounter the scenarios they describe.
3. NIST SP 800-86 when you need to argue for an evidence-handling decision.

For a specific situation (zero-day / cloud / ransomware):
1. Skim the topical section above.
2. Cross-reference with the [`agentic-dart` playbook v3](https://github.com/Juwon1405/agentic-dart/blob/main/dart_playbook/senior-analyst-v3.yaml) which encodes much of the *operational* synthesis of these doctrines.

---

## 🇰🇷 Korean language documents (한국어)

- **KISA — 침해사고 분석 절차 안내서** (`KISA/`)
- **KISA — 민간부분 침해사고 대응 안내서** (`KISA/`)
- **KR_FSEC** (Korean financial sector — `KR_FSEC/`)

---

## 📜 License & attribution

All documents in this directory **retain their original licenses and copyright**. NIST publications are public domain (US Government). SANS papers are typically released under SANS's own permissive distribution terms. ENISA, ACSC, KISA, etc. publications follow their respective publisher terms.

This is an **archive for personal reference and educational use.** If a referenced document belongs to you and you'd like it removed or re-attributed, please [open an issue](https://github.com/Juwon1405/GitNote/issues).

---

← [Back to GitNote root](../README.md)
