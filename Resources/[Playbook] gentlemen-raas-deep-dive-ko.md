# [Playbook] The Gentlemen RaaS — 심층 행위분석 핸드북 🎩

> 공격자 그룹 **The Gentlemen**(젠틀맨) 에 대한 한글 심층 분석 핸드북.
> 원문: **[Check Point Research — *Thus Spoke the Gentlemen* (2026)](https://research.checkpoint.com/2026/thus-spoke-the-gentlemen/)**
> 유출된 내부 백엔드 DB("Rocket")와 운영자 채팅 로그를 기반으로 한 그룹 내부 행위 분석입니다.
>
> **작성일:** 2026-06-04 · **분류:** Threat Intelligence / Ransomware Actor Profile
> **관련 문서:** [`[Playbook] 2026 Ransomware Actor Handbook`](%5BPlaybook%5D%20ransomware-2026-actor-handbook.md) (§1 The Gentlemen)

---

## 🎯 이 핸드북의 목적

기존 [2026 랜섬웨어 액터 핸드북](%5BPlaybook%5D%20ransomware-2026-actor-handbook.md)이 "교전 순간 빠른 식별"용 요약이라면, 이 문서는 **The Gentlemen이라는 조직이 내부에서 실제로 어떻게 굴러가는지** — 조직 구성, 도구 체계, 메신저·통신 방식, 자금 세탁, AI 활용까지 — 를 다루는 **행위 중심(behavioral) 심층 프로파일**입니다.

> ⚠️ **출처 신뢰도 주의:** 이 분석의 상당 부분은 2026년 5월 유출된 그룹 내부 DB와 채팅 로그에서 나온 것입니다. 운영자들의 자기 진술(예: 자금 세탁 수법, AI 활용)은 과장·허위일 수 있으니 정황 증거로만 활용하세요.

---

## 1️⃣ 그룹 개요 (Overview)

| 항목 | 내용 |
|---|---|
| **그룹명** | The Gentlemen (셀프 브랜딩: "신사들") |
| **유형** | RaaS (Ransomware-as-a-Service) |
| **등장 시점** | 2025년 중반 |
| **규모** | 2026년 1분기까지 약 **332개 피해 조직** 공개 (5개월간) |
| **위상** | 공개 피해자 수 기준 **2위 RaaS 프로그램** |
| **수익 분배** | 제휴사(affiliate) **90%** / 운영자(operator) **10%** — 작전별로 다시 분배 |
| **핵심 운영자** | `zeta88` (별칭 `hastalamuerte`) — 관리자(admin) |

대규모로 빠르게 성장한, **상품화된 랜섬웨어 인프라 + 숙련된 휴먼 오퍼레이터**가 결합된 성숙한 RaaS 생태계입니다.

---

## 2️⃣ 조직 구조 (Organization)

운영자 약 9명 + 제휴 신원(affiliate identity) 8개로 구성되며, 역할이 명확히 분업화돼 있습니다.

### 핵심 리더십

| 핸들 | 역할 |
|---|---|
| **zeta88 / hastalamuerte** | 관리자. 커스텀 락커·RaaS 패널·인프라 구축 및 유지, 수익 분배 관리, **직접 침해에도 참여** |
| **qbit** | 정찰(recon), Fortinet/Cisco 타겟팅, 지속성 확보, EDR 우회 담당 |
| **quant** | 로그 기반 접근(OWA/O365 자격증명) 전문, 커스텀 데이터 수집기 `buildx641` 유지 |

### 지원 멤버

`Wick`, `mAst3r`, `Protagor`, `Bl0ck`, `JeLLy`, `Kunder`, `Mamba` — 레드팀, 광고 파트너, 액세스 브로커, 건별 협업자 역할.

### 내부 관리자 계정 (Rocket DB 유출, 2026-05)

`zeta88`, `3NT3R`, `B1d3n`, `C0CA`, `d0wnloAd1`, `equal1z3r`, `F3N1X`, `Gblog88`, `JLL`, `LDW`, `n0n3`, `PRTGRS`, `W1Z` — 총 13개 이상의 관리 계정이 shadow 파일에서 노출.

---

## 3️⃣ 공격 기법 (TTPs) — 단계별

### 🔓 초기 침투 (Initial Access)

- **노출된 엣지 장비 익스플로잇** — Fortinet FortiGate, Cisco 장비, VPN 엔드포인트
- 관리 인터페이스 대상 **자격증명 무차별 대입(brute-force)**
- 서드파티 "봇" 공급자 / 액세스 브로커로부터 **접근 권한 구매**
- 데이터 유출 검색 엔진에서 **자격증명 수집(harvesting)**

### ⬆️ 권한 상승 & 지속성 (PrivEsc & Persistence)

- Active Directory 정찰 및 조작
- **인증서 남용** — ADCS 설정 오류(misconfiguration) 악용
- **Cloudflare Zero Trust 터널**을 통한 클라우드 지속성 확보
- 레지스트리 기반 권한 상승

### 🥷 방어 우회 (Defense Evasion)

- 레지스트리 조작을 통한 **EDR/백신 비활성화**
- **BYOVD** (Bring-Your-Own-Vulnerable-Driver) — 취약 드라이버 반입
- Windows 로깅 및 **ETW(Event Tracing for Windows) 무력화**
- **NTDLL 언후킹(unhooking)**
- **하드웨어 브레이크포인트 제거** (디버깅/후킹 탐지 회피)

### ↔️ 측면 이동 (Lateral Movement)

- Active Directory 자격증명 탈취
- **브라우저 세션 하이재킹**
- 다중 터널/프록시 구성, 보안 설정 완화

### 📤 데이터 유출 (Exfiltration)

- **NAS 장비, 백업 시스템, 가상화 인프라**를 표적
- 대규모 데이터 이동을 위한 자동화 도구 활용

### 🔒 암호화 배포 (Impact)

- 관리자 세션을 활용한 **커스텀 락커** 배포
- 네트워크 전체로 빠른 전파 (백그라운드 모드 / 전체 암호화 변종 존재)

---

## 4️⃣ 도구 & 인프라 (Tooling)

> 분업화된 만큼 도구 체계도 방대합니다. 방어자 입장에서 **이 도구 이름들이 탐지 헌팅의 키워드**가 됩니다.

### 🎮 C2 / 원격 접근

| 도구 | 용도 |
|---|---|
| **ZeroPulse** | 원격 접근 / C2 프레임워크 |
| **Velociraptor** | 은밀한 C2 플랫폼 (메모리/LSASS 덤핑) — *정상 DFIR 도구의 악용* |
| **Cloudflare Zero Trust / Tunnels** | HTTPS 기반 은닉 터널링 |
| **커스텀 VPN** | WireGuard, OpenVPN, Double-VPN 구성 |

### ⚔️ 공격 작전

| 도구 | 용도 |
|---|---|
| **NetExec / NXC** | AD/SMB/WinRM 익스플로잇 |
| **TaskHound** | 권한 남용 / 지속성 |
| **PrivHound** | 로컬 권한 상승 경로 탐색 |
| **RelayKing-Depth** | NTLM relay 익스플로잇 |
| **CertiHound** | ADCS 설정 오류 탐지 |
| **Titanis** | Windows 로깅 / ETW 조작 |
| **MANSPIDER** | 파일 공유(share) 검색 |
| **PowerZure** | Azure 설정 오류 남용 |
| **RegPwn** | 레지스트리 기반 권한 상승 (MSI 서비스 남용) |
| **KslDump / KslKatz** | Kerberos / LSASS 자격증명 덤핑 |

### 🛡️ EDR/AV 우회

| 도구 | 용도 |
|---|---|
| **EDRStartupHinder** | 시작 시 EDR 프로세스 차단 |
| **gfreeze** | EDR 작동 방해 |
| **glinker** | EDR 우회 컴포넌트 |
| **DumpBrowserSecrets** | 브라우저 자격증명 탈취 |
| **zerosalarium** | ETW/로깅 우회 기법 참조 |

### 🔭 스캐닝 / 보조

`gogo.exe` (포트/서비스 스캐너) · `Sputnik` (OSINT 브라우저 확장) · `chamd5.org` / `hashcracking_bot` (패스워드 크래킹 서비스) · `NXC 사용 가이드` (내부 운영 매뉴얼)

---

## 5️⃣ 메신저 & 통신 방식 (Communication) 💬

> 사용자께서 특히 관심 가지신 **메신저·통신 행위분석** 파트입니다.

| 채널 | 용도 |
|---|---|
| **언더그라운드 포럼** | RaaS 모집, 피해 데이터 판매 |
| **내부 채팅 채널** | 운영 조율 — `INFO`, `general`, `TOOLS`, `PODBOR` 채널로 분리 운영 |
| **TOX (P2P 메신저)** | 운영자 간 직접 통신 — **중앙 서버 없는 P2P라 추적이 어려움** |
| **DLS (Data Leak Site)** | onion 주소 — 피해자 공개 및 컨택 |

### 🆔 주요 TOX ID (IOC)

```
관리자(Administrator):
F8E24C7F5B12CD69C44C73F438F65E9BF560ADF35EBBDF92CF9A9B84079F8F04060FF98D098E

가장 활발한 제휴사(Affiliate):
98C132E2B20B531BE6604397D97040C1E9EB42FCE12EDF119BCE8B4031CA5C70DAF5E65FA3C3
```

> **행위 분석 포인트:** 총 8개 제휴사 TOX ID에 걸쳐 **29개 고유 캠페인**이 식별됐고, 그중 **관리자(zeta88)의 TOX ID가 4건의 개별 침해에서 직접 관찰**됨 → 관리자가 단순 인프라 운영자가 아니라 **현장 침해에 직접 손을 대는** 하이브리드 운영 방식임이 확인됨.

---

## 6️⃣ 악용 취약점 (CVE)

| CVE | 대상 / 내용 |
|---|---|
| **CVE-2024-55591** | FortiOS 관리 인터페이스 취약점 — 노출된 Fortinet 장비 초기 침투 |
| **CVE-2025-32433** | Erlang SSH 취약점 (Cisco 맥락) — PoC 적극 평가·테스트 중 |
| **CVE-2025-33073** | NTLM reflection/relay 취약점 — RelayKing 연동으로 스캔·익스플로잇 |

**기법 기반 익스플로잇:** RegPwn을 통한 MSI 서비스 남용 · **Veeam 백업 인프라** 설정 오류 · **iDRAC / Dell** 관리 인터페이스 취약점 · WPR/AutoLogger/ETW 조작

---

## 7️⃣ 멀웨어 상세 (Locker)

| 특성 | 값 |
|---|---|
| **언어** | Go 기반 커스텀 락커 (Windows/Linux 다중 OS) |
| **바탕화면** | `gentlemen.bmp` |
| **랜섬노트** | `README-GENTLEMEN.txt` |
| **모드** | 백그라운드 모드 / 전체 시스템 암호화(FULL) 변종 |
| **전파** | 캠페인별 다중 변종 배포, 네트워크 전체 고속 암호화 |

### 🔍 YARA 탐지 룰 (Check Point Research)

```yara
rule thegentlemen_ransomware
{
    meta:
        author = "@Tera0017/Check Point Research"
        description = "The Gentlemen Ransomware written in GO."
    strings:
        $string1 = "Silent mode (don't rename files)"
        $string2 = "Encrypt only mapped and UNC network shares"
        $string3 = "README-GENTLEMEN.txt"
        $string4 = "gentlemen.bmp"
        $string5 = "gentlemen_system"
        $string6 = "[+] Encryption started. Going background..."
        $string7 = "[+] FULL Encryption started"
    condition:
        uint16(0) == 0x5A4D and 4 of them
}
```

---

## 8️⃣ 자금 운영 & 세탁 (Financial Ops) 💰

### 협상 전술

- 문서화된 사례: 초기 요구 **$250,000** → 최종 지급 **$190,000**
- `zeta88`이 **GDPR 위반·평판 훼손을 강조하는 맞춤형 후속 협박 편지**를 직접 작성

### 비트코인 세탁 수법 (자기 진술 기반)

- "buy desk"를 통한 거래소 체인 호핑 — **약 800건** 거래 기록
- 거래 전 **AML 점수 확인**
- **Tinkoff 은행 QR 코드 현금화** (최소 40만 루블)
- 물리적 P2P OTC 현금 전달
- KYC 회피용 **비수탁(non-custodial) 지갑** 사용 — Guarda, Trust Wallet, Exodus

---

## 9️⃣ AI 활용 (AI Integration) 🤖

| 구분 | 내용 |
|---|---|
| **실제 사용** | `zeta88`이 AI 보조 코딩으로 **GLOCKER 관리 패널을 3일 만에** 개발 |
| **선호 모델** | DeepSeek, Qwen, Kimi, Emi (코딩·기술 질의) |
| **활용 방식** | FortiGate 내부 구조 등 기술 레퍼런스 빠른 조회용 |
| **계획 단계** | 로컬 호스팅 **무검열 LLM**으로 피해 데이터 분석 / 대량 데이터 분류 자동화 (구현 여부 불명확) |

---

## 🔟 경쟁 그룹 관계 & 인텔리전스 (Ecosystem)

| 대상 그룹 | The Gentlemen의 태도 |
|---|---|
| **HelloKitty** | 브랜드 인지도 긍정적으로 평가 |
| **Dragon Force** | 신뢰성 있는 최상위 프로그램으로 인정 |
| **Black Basta / Devman** | 적대적 — 특히 운영자 "David"에게 |

- 경쟁 그룹(특히 Black Basta)의 **유출된 협상 내용을 능동적으로 모니터링**
- Black Basta 연구에서 **코드 서명 인증서 남용 기법**을 차용

---

## 📌 사례 연구 — 데이터 재무기화 (Cross-Campaign Reuse)

**2026년 4월, 영국 소프트웨어 컨설팅사 침해** → 탈취 데이터를 **터키 기업 공격에 재활용**:

1. 터키 피해자를 DLS에 공개하면서 영국 컨설팅사를 **"액세스 브로커"로 명시**
2. 영국사의 내부 문서(마이그레이션/프로젝트 파일)로 **터키 기업 타겟팅 정보 강화**
3. 터키 피해자에게 **컨설팅사를 상대로 법적 조치를 부추기는** 이중 압박 협박
4. 캠페인 간 데이터를 정찰 강화용으로 재사용

> **시사점:** 한 번의 침해가 끝이 아니라, 탈취된 데이터가 **다음 표적의 정찰 자산**으로 순환됩니다. 협력업체·공급망 노출 데이터의 2차 피해를 반드시 고려해야 합니다.

---

## 🗄️ 내부 DB 유출 (Internal Leak, 2026-05-04~05)

"Rocket" 백엔드 DB 유출로 노출된 정보:

- 13개+ 관리 계정이 담긴 내부 shadow 파일
- 부분 채팅 로그 **44.4 MB** (전체 약 **16.22 GB**)
- 운영 조율 내역, 도구 인벤토리, 피해자 배정
- NAS / 스토리지 인프라 구성

> 이 유출이 본 Check Point 분석의 1차 사료(史料)입니다.

---

## 🚩 침해 지표 (IOCs)

### 파일 해시 (SHA-256)

| OS | 개수 | 예시 |
|---|---|---|
| **Windows** | 30 | `025fc0976c548fb5a880c83ea3eb21a5f23c5d53c4e51e862bb893c11adf712a`<br>`1334f0189a8e6dbc48456fa4b482c5726ab7609f7fa652fcc4c1a96f2334436f`<br>`1af419b36a5edefef387409e2b3248c9223f7dc49a4f7b15ea095d371c3a70b2` |
| **Linux** | 3 | `1eece1e1ba4b96e6c784729f0608ad2939cfb67bc4236dfababbe1d09268960c`<br>`5dc607c8990841139768884b1b43e1403496d5a458788a1937be139594f01dca`<br>`788ba200f776a188c248d6c2029f00b5d34be45d4444f7cb89ffe838c39b8b19` |

> 전체 33개 해시 및 추가 IOC는 **[원문 Appendix](https://research.checkpoint.com/2026/thus-spoke-the-gentlemen/)** 참조.

### 기타 IOC

- **TOX ID** — §5 참조
- **파일 흔적** — `gentlemen.bmp`, `README-GENTLEMEN.txt`, `gentlemen_system`
- **도구 바이너리** — `gogo.exe`, `buildx641`, `EDRStartupHinder`, `gfreeze`, `glinker`

---

## 🗺️ MITRE ATT&CK 매핑

| 전술 (Tactic) | 기법 (Technique) |
|---|---|
| **Initial Access** | Exploit Public-Facing Application (T1190), Valid Accounts (T1078) |
| **Execution** | Command and Scripting Interpreter (T1059), Native API (T1106) |
| **Persistence** | Account Manipulation (T1098), Valid Accounts (T1078) |
| **Privilege Escalation** | Local PrivEsc, Active Directory 남용 |
| **Defense Evasion** | Modify Registry (T1112), Disable/Modify Tools (T1562), Masquerading (T1036), Rootkit (T1014) |
| **Credential Access** | OS Credential Dumping (T1003), Brute Force (T1110) |
| **Discovery** | Account / Network Share / System Info Discovery (T1087/T1135/T1082) |
| **Lateral Movement** | Remote Services (T1021), Windows Admin Shares |
| **Collection** | Data Staged (T1074), Screen Capture (T1113) |
| **Exfiltration** | Data Transfer Size Limits (T1030) |
| **Impact** | Data Encrypted for Impact (T1486), Inhibit System Recovery (T1490) |

---

## 🛡️ 방어자 관점 핵심 정리 (Defender Takeaways)

| 관찰 신호 | 의미 | 즉시 조치 |
|---|---|---|
| Fortinet/Cisco 엣지 장비 + 비정상 관리자 로그인 | 초기 침투 시도 | CVE-2024-55591 패치 확인, 관리 인터페이스 인터넷 노출 차단 |
| **Velociraptor** 가 IR 도구로 배포되지 않았는데 존재 | C2 악용 | 정상 DFIR 배포 이력과 대조, 메모리/LSASS 접근 헌팅 |
| **Cloudflare Tunnel** 무단 설치 | 은닉 지속성 | egress에서 비인가 cloudflared 차단 |
| ADCS 인증서 발급 이상 | CertiHound 정찰 | 인증서 템플릿 권한 감사 |
| NTLM relay 스캔 (CVE-2025-33073) | RelayKing 활동 | SMB 서명 강제, EPA 적용 |
| `gentlemen.bmp` / `README-GENTLEMEN.txt` | **암호화 진행 중** | 즉시 격리 — 이미 늦은 단계 |
| NAS / Veeam / 백업 인프라 접근 | 유출 + 복구 무력화 준비 | 백업 네트워크 분리, immutable 백업 확인 |

> **핵심:** The Gentlemen은 **정상 도구(Velociraptor, Cloudflare, ADCS)를 악용**하고 **BYOVD·ETW 무력화로 텔레메트리를 끊는** 데 능합니다. 단일 시그니처 의존 탐지보다 **행위·이상치 기반 헌팅**이 필요합니다.

---

## 📚 참고 자료 (References)

- **[Check Point Research — *Thus Spoke the Gentlemen* (2026)](https://research.checkpoint.com/2026/thus-spoke-the-gentlemen/)** — 본 핸드북 원문
- **[Check Point Research — DFIR Report: The Gentlemen & SystemBC](https://research.checkpoint.com/2026/dfir-report-the-gentlemen/)** — 동일 그룹 기술 분석
- 내부 교차 참조: [`[Playbook] 2026 Ransomware Actor Handbook`](%5BPlaybook%5D%20ransomware-2026-actor-handbook.md) · [`[Playbook] identity-attacks-detection`](%5BPlaybook%5D%20identity-attacks-detection.md) · [`[Cheatsheet] evtx-threat-hunting-2026`](%5BCheatsheet%5D%20evtx-threat-hunting-2026.md)

---

## ↩️ Back

← [Resources/](../Resources/) · [GitNote root](../README.md)
