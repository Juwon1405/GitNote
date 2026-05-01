# [Cheatsheet] Cloud DFIR — AWS CloudTrail + Entra ID

> Cloud IR is a different game. **No memory dumps, no MFT, no Volatility.** Everything is API logs and identity events. Here's the practical triage flow.
>
> **Last updated:** 2026-05-01

---

## 🎯 Cloud IR mental model — what changes vs on-prem

| Concept | On-prem DFIR | Cloud DFIR |
|---|---|---|
| **Evidence source** | Disk + memory + EVTX | API audit logs (CloudTrail / Entra ID Sign-In Logs) |
| **Earliest IOC** | Process tree + MFT | First API call from suspicious source IP |
| **Persistence** | Run keys, services, scheduled tasks | IAM access keys, Lambda triggers, IAM role assumptions, cross-account roles |
| **Lateral movement** | Pass-the-Hash, RDP, WMI | `AssumeRole`, `GetSessionToken`, OAuth token theft |
| **"Reboot" equivalent** | Memory loss | **Log retention boundary** — past CloudTrail retention = blind |
| **Containment** | Network isolate | Disable IAM keys, revoke OAuth tokens, kill sessions |

---

## ☁️ AWS CloudTrail — top 10 events to surface

### 1. Root account API calls (T1078.004)
```
eventName: any
userIdentity.type == "Root"
```
**Root should never make API calls in steady state.** If you see any → critical alert.

### 2. IAM credential creation / modification (T1098.001)
```
eventName IN [
  CreateAccessKey, CreateLoginProfile, UpdateLoginProfile,
  AttachUserPolicy, AttachRolePolicy, PutUserPolicy,
  CreateUser, CreateRole, AddUserToGroup
]
```
Persistence in cloud is identity manipulation, not file modification.

### 3. CloudTrail tampering (T1562.008)
```
eventName IN [
  StopLogging, DeleteTrail, UpdateTrail, PutEventSelectors
]
```
Attackers turning off logging is the cloud equivalent of `wevtutil cl`.

### 4. Console login from unusual IP (T1078)
```
eventName: ConsoleLogin
sourceIPAddress NOT IN <known-corp-egress>
userAgent: contains "Mozilla" but unusual fingerprint
```
Cross-reference `sourceIPAddress` with VirusTotal / AbuseIPDB / your TI.

### 5. AssumeRole chains (T1550.001)
```
eventName: AssumeRole
userIdentity.type: AssumedRole
       (i.e. assuming a role from already-assumed credentials)
```
**Multi-hop role chains** are a top lateral movement technique in AWS.

### 6. S3 bucket policy changes / public exposure (T1530)
```
eventName IN [
  PutBucketPolicy, PutBucketAcl, PutPublicAccessBlock,
  DeletePublicAccessBlock
]
requestParameters: contains "Principal: *" OR "AllUsers"
```

### 7. EC2 instance compromise indicators (T1578)
```
eventName IN [
  RunInstances, ModifyInstanceAttribute, AuthorizeSecurityGroupIngress
]
       AND requestParameters indicates: 0.0.0.0/0 ingress to admin port
```

### 8. KMS key disable / delete (T1485)
```
eventName IN [
  DisableKey, ScheduleKeyDeletion, PutKeyPolicy
]
```
Disabling KMS keys is a way to deny recovery.

### 9. GuardDuty / Security Hub disable
```
eventName IN [
  DisableGuardDuty, DeleteDetector,
  DisableSecurityHub, BatchDisableStandards
]
```
Disabling cloud-native security tooling = active adversary action.

### 10. CreateLoginProfile on existing user (T1098.001)
```
eventName: CreateLoginProfile
       AND target user existed before but had no console access
```
Adding console password to a programmatic-only user = backdoor creation.

---

## 🔧 Athena queries — copy-paste ready

Once you've enabled CloudTrail → S3 → Athena (you should), here are queries that work:

### Recent IAM key creation
```sql
SELECT
  eventTime, userIdentity.userName as user, sourceIPAddress,
  requestParameters.userName as target_user,
  responseElements.accessKey.accessKeyId as new_key
FROM cloudtrail_logs
WHERE eventName = 'CreateAccessKey'
  AND eventTime >= date_format(date_add('day', -30, current_timestamp), '%Y-%m-%dT%H:%i:%sZ')
ORDER BY eventTime DESC;
```

### AssumeRole chains (multi-hop)
```sql
SELECT
  eventTime, sourceIPAddress, userIdentity.arn as caller,
  requestParameters.roleArn as assumed_role,
  responseElements.assumedRoleUser.arn as new_identity
FROM cloudtrail_logs
WHERE eventName = 'AssumeRole'
  AND userIdentity.type = 'AssumedRole'  -- already-assumed assuming again
  AND eventTime >= date_format(date_add('day', -7, current_timestamp), '%Y-%m-%dT%H:%i:%sZ')
ORDER BY eventTime;
```

### Console logins from new IPs (last 7d vs prior 90d baseline)
```sql
WITH baseline AS (
  SELECT DISTINCT sourceIPAddress
  FROM cloudtrail_logs
  WHERE eventName = 'ConsoleLogin'
    AND eventTime BETWEEN date_format(date_add('day', -90, current_timestamp), '%Y-%m-%dT%H:%i:%sZ')
                      AND date_format(date_add('day', -7, current_timestamp), '%Y-%m-%dT%H:%i:%sZ')
)
SELECT eventTime, userIdentity.userName, sourceIPAddress, userAgent
FROM cloudtrail_logs
WHERE eventName = 'ConsoleLogin'
  AND eventTime >= date_format(date_add('day', -7, current_timestamp), '%Y-%m-%dT%H:%i:%sZ')
  AND sourceIPAddress NOT IN (SELECT sourceIPAddress FROM baseline);
```

---

## 🔐 Entra ID (Azure AD) — top 10 attack signatures

### 1. Device Code phishing (T1566.004 + T1078.004)
**Hot 2025-2026 TTP.** Attacker initiates a device code flow, sends user a "type this code at microsoft.com/devicelogin" link.

```kql
SigninLogs
| where ResourceDisplayName == "Microsoft Authentication Broker"
   or AuthenticationProtocol == "deviceCode"
| project TimeGenerated, UserPrincipalName, IPAddress, Location, AuthenticationProtocol
```

### 2. PRT (Primary Refresh Token) theft / replay (T1528)
```kql
SigninLogs
| where AuthenticationDetails contains "PrimaryRefreshToken"
| where ConditionalAccessStatus == "success"
   and IPAddress != <expected-corp-ranges>
```

### 3. Conditional Access policy bypass (T1556)
```kql
AuditLogs
| where OperationName == "Update conditional access policy"
   or OperationName == "Delete conditional access policy"
| project TimeGenerated, OperationName, InitiatedBy, TargetResources
```

### 4. MFA fatigue / bombing (T1621)
```kql
SigninLogs
| where ResultType == 50140  // "Strong authentication required"
   or ResultType == 50158    // "External security challenge not satisfied"
| summarize count() by UserPrincipalName, IPAddress, bin(TimeGenerated, 5m)
| where count_ > 5  // burst pattern
```

### 5. Service Principal / Application credential changes (T1098.001)
```kql
AuditLogs
| where OperationName in (
    "Add owner to application",
    "Add service principal credentials",
    "Update application certificates and secrets management",
    "Consent to application"
)
| project TimeGenerated, OperationName, InitiatedBy, TargetResources
```

### 6. Federated domain trust modification (T1606.002)
```kql
AuditLogs
| where OperationName in ("Set domain authentication", "Set federation settings on domain")
```
**Critical** — this is the Solorigate / SolarWinds-style golden SAML setup.

### 7. Mailbox forwarding rule creation (T1114.003)
Done via Exchange Online but visible in:
```kql
OfficeActivity
| where Operation in ("New-InboxRule", "Set-InboxRule", "Set-Mailbox")
| where Parameters contains "Forward" or Parameters contains "RedirectTo"
```

### 8. Risky sign-in events (Microsoft's own ML)
```kql
SigninLogs
| where RiskLevelDuringSignIn in ("medium", "high")
   or RiskState == "atRisk"
```

### 9. New OAuth app consent (T1528)
```kql
AuditLogs
| where OperationName == "Consent to application"
| extend AppName = tostring(TargetResources[0].displayName)
| project TimeGenerated, InitiatedBy, AppName, ResultStatus
```
Look for unsanctioned third-party apps users consented to.

### 10. Privileged role assignment (T1098.003)
```kql
AuditLogs
| where OperationName == "Add member to role"
| where TargetResources has_any ("Global Administrator", "Privileged Role Administrator", "Application Administrator", "Cloud Application Administrator")
```

---

## 🛠️ Tools to know

| Tool | What it does | Where |
|---|---|---|
| **Stratus Red Team** | Granular AWS / Azure / GCP attack emulation | [github.com/DataDog/stratus-red-team](https://github.com/DataDog/stratus-red-team) |
| **CloudTrail Explorer** | Open-source log explorer | various forks |
| **Cartography** (Lyft) | Asset graph for cloud post-IR scope | [github.com/lyft/cartography](https://github.com/lyft/cartography) |
| **Pacu** | AWS exploitation framework — useful to **understand attacker tools** | [github.com/RhinoSecurityLabs/pacu](https://github.com/RhinoSecurityLabs/pacu) |
| **AzureHound / BloodHound CE** | Map Entra ID attack paths | [github.com/SpecterOps/BloodHound](https://github.com/SpecterOps/BloodHound) |
| **Microsoft Sentinel KQL hunting library** | Pre-built queries for the SigninLogs / AuditLogs above | [github.com/Azure/Azure-Sentinel](https://github.com/Azure/Azure-Sentinel) |
| **MITRE Cloud Matrix** | Cloud-specific ATT&CK techniques | [attack.mitre.org/matrices/enterprise/cloud](https://attack.mitre.org/matrices/enterprise/cloud) |

---

## 📦 What to capture during cloud IR

1. **CloudTrail logs** — last 90 days minimum. Export to S3 + back up to a separate AWS account.
2. **VPC Flow Logs** — for the affected accounts/regions.
3. **GuardDuty findings** — the last 90 days.
4. **IAM snapshot** — `aws iam get-account-authorization-details` (full IAM state at incident time).
5. **EC2 instance metadata** — running instances, their tags, their attached IAM roles.
6. **Lambda function inventory** — list + most recent code for any function modified during the suspect window.
7. **S3 bucket policies** — current state of every bucket.

For Entra ID:
1. **Sign-In Logs** — last 30 days (default retention).
2. **Audit Logs** — last 30 days.
3. **Risky sign-ins / risky users** — Identity Protection blade.
4. **Conditional Access policies** — current snapshot + change history.
5. **Service Principal credentials** — list of all SPs and their cert/secret expiration.

---

## 🚨 Key 2026 case studies to read

- **[Hive Security — Entra ID Attacks: Device Code, PRT, Conditional Access Bypass](https://hivesecurity.gitlab.io/blog/dfir-incident-response-complete-guide-2026/)** (2026)
- **[CrowdStrike — Cloud IAM Lateral Movement](https://www.crowdstrike.com/)** — recent reports
- **[Mandiant M-Trends 2026](https://cloud.google.com/security/resources/m-trends)** — cloud-attack chapters
- **[CISA Cloud Security TTPs](https://www.cisa.gov/news-events/cybersecurity-advisories)** — publishes joint advisories on cloud campaigns

---

## ↩️ Back

← [Resources/](../Resources/) · [GitNote root](../README.md)
