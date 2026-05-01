# [Playbook] Identity-Centric Attacks — Detection

> Active Directory + Entra ID attacks are the **#1 lateral movement vector** in 2025-2026 intrusions. This playbook covers detection signatures for the techniques actually used.
>
> **Last updated:** 2026-05-01

---

## 🎯 The 8 identity attacks that actually matter

| Attack | MITRE | Why it matters | Hard to detect? |
|---|:---:|---|:---:|
| **Kerberoasting** | T1558.003 | Service account credential theft offline | Medium |
| **AS-REP Roasting** | T1558.004 | Pre-auth disabled accounts → offline crack | Easy |
| **Pass-the-Hash** | T1550.002 | NTLM hash reuse for lateral movement | Medium |
| **Pass-the-Ticket** | T1550.003 | Kerberos ticket reuse | Hard |
| **Golden Ticket** | T1558.001 | Forged TGT — full domain compromise | Very Hard |
| **Silver Ticket** | T1558.002 | Forged service ticket — single-service compromise | Very Hard |
| **DCSync** | T1003.006 | Replicating krbtgt + all hashes | Medium-Hard |
| **DPAPI master key theft** | T1555.004 | Decrypt user secrets offline | Hard |

Plus modern Entra ID equivalents:

| Attack | MITRE | Why it matters |
|---|:---:|---|
| **Device Code phishing** | T1566.004 | OAuth flow abuse — bypasses traditional MFA UX |
| **PRT theft / replay** | T1528 | Primary Refresh Token = persistent SSO across all M365 |
| **Token theft via infostealers** | T1539 | Browser cookie / token caches → seamless session hijack |
| **MFA fatigue / bombing** | T1621 | Spam push notifications until user approves |

---

## 1️⃣ Kerberoasting (T1558.003)

**The attack:** Anyone in AD can request a service ticket for any account with an SPN. The ticket is encrypted with the service account's password hash. Crack offline, profit.

### Detection signatures

```yaml
# Sigma-ish detection
title: Kerberoasting Activity (Multiple TGS Requests)
detection:
  selection:
    EventID: 4769
    TicketEncryptionType: '0x17'  # RC4-HMAC (modern environments should use AES = 0x12)
    TicketOptions: '0x40810010'   # without canonicalize flag
  filter:
    ServiceName|startswith: 'krbtgt'  # exclude TGT requests
  condition: selection and not filter
  threshold:
    count: 5
    timeframe: 60s
    by: source_ip
```

### What you'll actually see in EVTX

```
EID 4769  Kerberos Service Ticket Operation
  ServiceName: HOST/myserver$  OR  MSSQLSvc/sql.corp.local
  TicketEncryptionType: 0x17  ← RED FLAG (RC4)
  TicketOptions: 0x40810010
  Account Name: <attacker>
  Source IP: <attacker_workstation>
```

### Detector logic

1. Count 4769 requests with `TicketEncryptionType=0x17` per source IP per 60s
2. Threshold: > 5 requests = likely Kerberoasting tool (Rubeus, Impacket GetUserSPNs)
3. Pivot: cross-reference with `TicketOptions` flag patterns

### Defender response

- Reset the targeted service account's password (must be ≥25 chars to be uncrackable in reasonable time)
- Migrate service to gMSA (Group Managed Service Account) — automatic password rotation
- Enable AES-only Kerberos (`0x12`) at domain level

---

## 2️⃣ AS-REP Roasting (T1558.004)

**The attack:** Accounts with "Do not require Kerberos pre-authentication" set can be queried for AS-REP responses, encrypted with the account's password hash. Crack offline.

### Detection signature

```yaml
title: AS-REP Roasting (Multiple AS Requests for Pre-Auth-Disabled Accounts)
detection:
  selection:
    EventID: 4768
    PreAuthType: '0'  # ← key — pre-auth NOT performed
    TicketEncryptionType: '0x17'
  threshold:
    count: 3
    timeframe: 60s
    by: source_ip
```

### Why it matters

Pre-auth is normally on by default, but legacy apps sometimes disable it. **Even ONE account with pre-auth off** is a domain-wide risk.

### Defender response

```powershell
# Find all accounts with pre-auth disabled
Get-ADUser -Filter * -Properties DoesNotRequirePreAuth |
  Where-Object {$_.DoesNotRequirePreAuth -eq $true} |
  Select-Object Name, SamAccountName, Enabled
```

For each match: **enable pre-auth** unless there's a documented business reason.

---

## 3️⃣ Pass-the-Hash (T1550.002)

**The attack:** Use an NTLM hash directly without knowing the plaintext password. Mimikatz `sekurlsa::pth` or similar.

### Detection signatures

```yaml
title: Pass-the-Hash — NTLM Authentication for Privileged Account
detection:
  selection_logon:
    EventID: 4624
    LogonType: 9        # NewCredentials (PtH classic)
    AuthenticationPackage: 'NTLM'
    LogonProcess: 'seclogo'
  selection_priv:
    EventID: 4624
    LogonType: 3        # Network
    AuthenticationPackage: 'NTLM'
    TargetUserName|in:
      - 'Administrator'
      - 'svc_*'
      - 'admin_*'
  condition: selection_logon or selection_priv
```

### What's the smoking gun?

- **NTLM authentication for a Domain Admin account** in a modern Kerberos-only environment = always suspicious
- LogonType 9 + LogonProcess `seclogo` = textbook Mimikatz `sekurlsa::pth` signature

### Pivot pattern

```
T-0:    EID 4624 LogonType=9 (PtH)
T+30s:  EID 5145 (share access) on remote host
T+60s:  EID 4688 (process create) — psexec.exe / wmiexec.py / atexec
T+90s:  Lateral movement complete
```

When you see this pattern within 90 seconds, treat as confirmed lateral movement.

---

## 4️⃣ Golden Ticket (T1558.001)

**The attack:** Compromise the `krbtgt` account hash → forge arbitrary TGTs claiming to be any user. Effectively domain god mode.

### Detection signatures

#### Signal A: Admin-token usage (4672) without preceding credential access
```yaml
title: Suspicious Admin Privilege Without Cred-Access Precedent
detection:
  admin_logon:
    EventID: 4672
  threshold:
    correlate_back_within: 24h
    NOT preceded by: any of [4768 with TicketEncryptionType=0x12, 4624 LogonType=2 (interactive), credential_access_TTP]
```

If a user is granted admin privileges but there's no preceding interactive logon, no fresh TGT request, no MFA challenge → suspect Golden Ticket.

#### Signal B: Anomalously long ticket lifetime
```yaml
title: Ticket Lifetime Exceeds Domain Maximum
description: |
  Default Kerberos TGT lifetime is 10 hours. Default Mimikatz Golden Ticket = 10 years.
  If you see a TGT used > 10 hours from issue, investigate.
```

#### Signal C: Encryption type downgrade
```yaml
title: TGS Request With Old Encryption Type for Modern Domain
detection:
  EventID: 4769
  TicketEncryptionType: '0x17'  # RC4
  AND domain functional level >= 2008
```

Mimikatz Golden Tickets default to RC4. Modern domains use AES.

### Defender response

If Golden Ticket is suspected:
1. **Rotate krbtgt twice** (must be done twice with delay; one rotation only invalidates half the active tickets)
2. **Hunt for the original krbtgt compromise vector** (DCSync? AD database theft? domain admin compromise?)
3. **Treat the entire domain as compromised** — there is no half-measure recovery

---

## 5️⃣ DCSync (T1003.006)

**The attack:** Use `Replicating Directory Changes` permission to remotely replicate domain credentials, including krbtgt. Mimikatz `lsadump::dcsync`.

### Detection signature

```yaml
title: Suspected DCSync — Replication Request from Non-DC
detection:
  EventID: 4662
  ObjectType: '*Domain-DNS'
  Properties: '*DS-Replication-Get-Changes-All*'
  AccountName: NOT in known_domain_controllers
  AccountName: NOT in known_replication_service_accounts
```

### What you'll see

```
EID 4662  An operation was performed on an object
  Object Type: domainDNS
  Properties: %{1131f6aa-9c07-11d1-f79f-00c04fc2dcd2}  ← DS-Replication-Get-Changes-All GUID
  Account Name: <attacker>  ← NOT a DC computer account
```

The smoking gun is **a non-DC account exercising replication rights.**

---

## 6️⃣ Modern Entra ID — Device Code Phishing (T1566.004)

**The attack:** Attacker initiates an Azure AD device code flow, gets the code, sends user a "type this code at microsoft.com/devicelogin" link. User enters it → attacker gets the user's tokens.

### Detection (Microsoft Sentinel KQL)

```kql
SigninLogs
| where AuthenticationProtocol == "deviceCode"
   or ResourceDisplayName == "Microsoft Authentication Broker"
| where ResultType == 0  // success
| project TimeGenerated, UserPrincipalName, IPAddress, Location,
          DeviceDetail, AppDisplayName, AuthenticationProtocol
| where IPAddress != <known_corp_egress>
   or Location !in (<known_locations>)
```

### Why it bypasses MFA UX

- The user is **already authenticated** when they enter the code — no MFA prompt
- The "device" requesting the code can be anywhere
- User sees nothing suspicious; no app install, no permission prompt for unusual scopes

### Defender response

- **Disable device code flow for users who don't need it** (most don't):
  ```
  Conditional Access policy: block deviceCode for all except specific groups
  ```
- Train users: **Microsoft will never ask you to type a code from a link** — Microsoft's own apps generate the code on the device that's authenticating

---

## 7️⃣ MFA Fatigue / Bombing (T1621)

**The attack:** Attacker has the password (from infostealer log, prior breach, etc.). They trigger MFA push notifications repeatedly until the user, frustrated or distracted, taps Approve.

### Detection (KQL)

```kql
SigninLogs
| where ResultType == 50140  // "Strong authentication required"
   or ResultType == 50158    // External challenge not satisfied
| summarize attempts = count() by UserPrincipalName, IPAddress, bin(TimeGenerated, 5m)
| where attempts > 5
```

### What's the response?

1. **Number matching MFA** (Microsoft Authenticator) — user must type a number shown on the login screen, can't just tap Approve
2. **Prompted "additional context"** — show app name + location to user during prompt
3. **Lockout policy** — too many MFA failures = temporary account lockout (frustrate the attacker too)
4. **User training** — if you didn't initiate a login, deny + report

---

## 8️⃣ Token Theft via Infostealers (T1539)

**The attack:** Infostealer (Lumma, Vidar, Stealc) drops on user's box, exfils browser cookies + token caches. Attacker replays them = no MFA needed.

### Detection signatures

#### Signal A: Same session ID, different IP
```kql
SigninLogs
| where ResultType == 0  // success
| summarize ips = make_set(IPAddress) by SessionId, UserPrincipalName
| where array_length(ips) > 1
```

#### Signal B: New device with established account
```kql
SigninLogs
| where DeviceDetail.deviceId != ""
| extend deviceId = tostring(DeviceDetail.deviceId)
| join kind=leftanti (
    SigninLogs
    | where TimeGenerated < ago(7d)
    | distinct deviceId = tostring(DeviceDetail.deviceId)
) on deviceId
// Now you have first-seen-in-last-7d device IDs per user
```

### Defender response

- **Token binding** — when supported by app, bind tokens to TPM-backed device key
- **Conditional Access** — require compliant device + managed app
- **Continuous Access Evaluation (CAE)** — sessions auto-revoke when risk changes
- **Hunt for infostealer drops** — Stealer log monitoring services like Russian Market, Genesis market (when scrapers are available)

---

## 🛠️ Tools to know

| Tool | Side | What |
|---|:---:|---|
| **BloodHound** | Both | AD attack-path graph (CE = community open source) |
| **Rubeus** | Red | Kerberos ticket manipulation (Kerberoast / Golden / Silver) |
| **Mimikatz** | Red | The reference. Still works. PtH/PtT/DCSync/Golden/Silver |
| **Impacket** (`GetUserSPNs.py`, `secretsdump.py`) | Red | Python equivalents |
| **Hashcat** | Red | Crack the hashes Kerberoast/AS-REP gives you |
| **Pingcastle** | Blue | AD security audit (see what attackers will see) |
| **PurpleKnight** (Semperis) | Blue | Free AD security assessment |
| **AzureHound** | Both | Entra ID equivalent of BloodHound |
| **ROADtools** (Dirkjan) | Both | Azure AD enumeration + offensive |
| **MicroBurst** | Red | Azure attack toolkit |

---

## 📚 References

- **Sean Metcalf — adsecurity.org** — encyclopedia of AD attacks + detection
- **JPCERT/CC — Detecting Lateral Movement through Tracking Event Logs** — canonical reference
- **Sami Lamppu blog** — modern Entra ID attack chains
- **Dirk-jan Mollema (dirkjanm.io)** — top Azure AD security researcher
- **Mandiant — White Paper on Kerberos** — deep technical reference
- **Microsoft — Securing Privileged Access** — official defensive guidance

---

## ↩️ Back

← [Resources/](../Resources/) · [GitNote root](../README.md)
