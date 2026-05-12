# 2026-05-12 GitHub 전체 점검 & 일괄 정리 작업
> **결과:** 알림 노이즈 100% 차단 완료 (52/52 Actions OFF)

---

## 1. Executive Summary

| 항목 | 수치 |
|---|---:|
| 전체 리포 (public) | **147개** |
| 본인 작품 (own) | **8개** |
| Fork | **139개** |
| 활성 워크플로우로 알림 발생시키던 fork | **52개** |
| 본 작업으로 Actions OFF 처리 | **52개 (실패 0)** |
| 본인 작품 health | **8/8 green** |

**핵심 결과:** Inbox 알림 폭탄은 Fork 레포에 상속된 upstream 워크플로우가 secrets 부재로 100% 실패한 것이 원인. 본 작업으로 fork 단위 Actions를 일괄 OFF 처리 → 알림 즉시 차단. 본인 작품(`agentic-dart`, `juwon1405.github.io`, `Juwon1405`, `GitNote`, `yushin-*`, `skills-*`)은 모두 영향 없음.

---

## 2. 분류 결과 (147개)

| 카테고리 | 개수 | 조치 |
|---|---:|---|
| **A. 본인 작품** | 8 | 유지 + Health check 완료 |
| **B. 활성 워크플로우 Fork (소음원)** | 52 | **Actions OFF 일괄 처리 완료** |
| **C. 워크플로우 비활성 Fork** | 0 | — |
| **D. 워크플로우 없는 Fork** | 80 | 유신님 결정 사항 (유지/삭제) |

---

## 3. A. 본인 작품 8개 Health Check

| Repo | Workflows | Last Run | Conclusion | 분류 |
|---|---:|---|---|---|
| `agentic-dart` | 2 | 2026-05-12 | ✅ success | SANS 제출작 (최우선) |
| `juwon1405.github.io` | 1 | 2026-05-10 | ✅ success | GitHub Pages (4-surface) |
| `Juwon1405` | 0 | — | — | Profile README |
| `GitNote` | 0 | — | — | 갓노트 (이 문서가 들어가는 곳) |
| `yushin-gendfir-rag` | 0 | — | — | DFIR R&D |
| `yushin-mac-artifact-collector` | 0 | — | — | DFIR R&D |
| `yushin-mac-forensics-platform` | 0 | — | — | DFIR R&D |
| `skills-communicate-using-markdown` | 7 | 2026-03-01 | ✅ success | Skill |

> 결론: **빨간 실패 0건.** 본인 작품 모두 정상.

---

## 4. B. Fork Actions 일괄 OFF (52개)

GitHub REST API `PUT /repos/{owner}/{repo}/actions/permissions` 로 `{"enabled": false}` 일괄 적용. 응답 HTTP 204.

### 처리 명단

| # | Repo | 워크플로우 수 |
|---:|---|---:|
| 1 | `AgentGPT` | 4 |
| 2 | `armeria` | 12 |
| 3 | `Auto-GPT` | 1 |
| 4 | `Auto-GPT-Plugins` | 2 |
| 5 | `awesome` | 1 |
| 6 | `awesome-chatgpt-prompts` | 5 |
| 7 | `awesome-event-ids` | 2 |
| 8 | `awesome-forensics` | 1 |
| 9 | `awesome-incident-response` | 2 |
| 10 | `awesome-mac` | 1 |
| 11 | `awesome-memory-forensics` | 1 |
| 12 | `awesome-python` | 2 |
| 13 | `awesome-soc` | 1 |
| 14 | `ChatFred` | 1 |
| 15 | `ChatGPT-Desktop-Application` | 1 |
| 16 | `cleanrl` | 3 |
| 17 | `codescan-semgrep` | 14 |
| 18 | `connectors` | 6 |
| 19 | `CyberChef` | 3 |
| 20 | `DeTTECT` | 6 |
| 21 | `developer-roadmap` | 10 |
| 22 | `docker-elk` | 5 |
| 23 | `DSInternals` | 3 |
| 24 | `elastdocker` | 2 |
| 25 | `fish-shell` | 8 |
| 26 | `flare-vm` | 2 |
| 27 | `Ghost` | 14 |
| 28 | `grr` | 1 |
| 29 | `gym` | 2 |
| 30 | `Gymnasium` | 8 |
| 31 | `Harden-Windows-Security` | 12 |
| 32 | `hindsight` | 1 |
| 33 | `MHDDoS` | 2 |
| 34 | `openai-cookbook` | 3 |
| 35 | `openai-python` | 4 |
| 36 | `opencti` | 13 |
| 37 | `PettingZoo` | 9 |
| 38 | `puppeteer` | 12 |
| 39 | `QOwnNotes` | 9 |
| 40 | `quivr` | 4 |
| 41 | `radare2` | 7 |
| 42 | `sigma` | 11 |
| 43 | `Sooty` | 3 |
| 44 | `suricata-language-server` | 4 |
| 45 | `tensorflow` | 15 |
| 46 | `TextAttack` | 5 |
| 47 | `timesketch` | 6 |
| 48 | `uptime-kuma` | 18 |
| 49 | `webcrate` | 5 |
| 50 | `whisper` | 2 |
| 51 | `Yamato-Security-hayabusa` | 5 |
| 52 | `Zircolite` | 2 |

**총 비활성화된 워크플로우: 약 250개**

---

## 5. D. 워크플로우 없는 Fork 80개 (정리 대상 후보)

> 알림 노이즈는 없지만 프로필이 지저분해 보일 수 있음. 유신님 판단 대상.

### DFIR/SECURITY (48개) — 학습/참고 자료, 대부분 유지 권장

`awesome-honeypots`, `DFIR-automation-dfirwizard`, `Infornito`, `DFIR-OSX-osxcollector`, `SocAnalystArsenal`, `soc-threat-hunting`, `awesome-forensicstools`, `DFIR-SOC-Lab`, `DFIRLab`, `CrowdStrike-RTR-Scripts`, `mac4n6`, `udp2tcp`, `DFIR-OSX-CrowdStrike-Falcon-automactc`, `Yamato-Security-WELA`, `ESXiArgs-Recover`, `awesome-ctf`, `vidar_decrypt_strings`, `SANS-SCADA-DFIR-icsdfir`, `DFIR-aws-automated-incident-response-and-forensics`, `DFIR-Cheatsheet`, `mac_apt`, `machofile`, `TheHive`, `VECTR`, `TraxOsint`, `ExtAnalysis`, `commando-vm`, `Get-bADpasswords`, `Portable_Volatility`, `awesome-pentest`, `AutoIt-Ripper`, `Blue-Team-Notes`, `pimpmykali`, `Awesome-malware-analysis`, `Vulnerable-Code-Snippets`, `FSEventsParser`, `volatility`, `awesome-hacking`, `awesome-burp-extensions`, `blackhat-arsenal-tools`, `ForensicsTools`, `pyvfeed`, `ghidra`, `awesome-threat-detection`, `awesome-Infosec_Reference`, `awesome-cybersecurity-blueteam`, `awesome-security`, `awesome-PoC-in-GitHub`

### CAREER/STUDY (5개) — 유지 권장

`SOC-Analyst-Diploma`, `how_to_become_a_malware_analyst`, `SANS-Course-Indexes`, `kr-redteam-playbook`, `SANS-for509`, `SANS-SIFT-Workstation`, `Security-Datasets`, `cybersecurity-career-path`

### AI/LLM (16개) — 사용 빈도 낮으면 삭제 고려

`gpt-3`, `gpt-3_chrome_extension`, `nofwl`, `chat-todo-plugin`, `chatgpt-advanced`, `stablediffusion`, `Cyber-Security-chatGPT-prompt`, `hackerbot`, `openai-quickstart-node`, `StableLM`, `StableStudio`, `chatgpt`, `chatgpt-cli`, `hackGPT`, `deepl-for-slack`, `flasgger`

### UTIL/OTHER (11개) — 삭제 검토 대상

`FireEye-AX-API` (2017), `DynamicValueChallenge` (2019), `Edison` (2022), `twint` (2023), `Cloudwatch-bot` (2023), `email-header-analyzer` (2023), `Proxyman`, `awesome-nodejs`

### 삭제 1순위 후보 (2023년 이전, 최근 활동 없음)

| Repo | Last push |
|---|---|
| `FireEye-AX-API` | 2017-07-19 |
| `awesome-honeypots` | 2018-01-02 |
| `DynamicValueChallenge` | 2019-02-01 |
| `DFIR-automation-dfirwizard` | 2019-03-04 |
| `Infornito` | 2019-05-11 |
| `DFIR-OSX-osxcollector` | 2019-06-19 |
| `SocAnalystArsenal` | 2019-06-20 |
| `soc-threat-hunting` | 2020-07-27 |
| `gpt-3` | 2020-09-18 |
| `awesome-forensicstools` | 2020-11-16 |
| `DFIR-SOC-Lab` | 2021-05-03 |
| `DFIRLab` | 2021-05-07 |
| `CrowdStrike-RTR-Scripts` | 2021-08-12 |
| `mac4n6` | 2021-11-11 |
| `udp2tcp` | 2022-01-06 |
| `Edison` | 2022-01-24 |
| `DFIR-OSX-CrowdStrike-Falcon-automactc` | 2022-03-31 |
| `SANS-Course-Indexes` | 2022-04-18 |
| `SOC-Analyst-Diploma` | 2022-07-25 |

> 결정 시: 유신님이 위 명단 중 삭제할 것을 추려주시면, 동일한 PAT으로 일괄 삭제(`DELETE /repos/{owner}/{repo}`) 처리 가능.

---

## 6. 사용한 방법론 (재현 가능)

### 환경
- **PAT:** `juwon1405-all-deploy-for-claude-260625` (2026.06.25 만료, 모든 권한)
- **API:** GitHub REST API v3

### 식별 절차
```python
# 1. 전체 own 리포 목록
GET /user/repos?per_page=100&affiliation=owner

# 2. 각 fork의 워크플로우 파일 존재 여부
GET /repos/{owner}/{repo}/contents/.github/workflows

# 3. 각 워크플로우의 state 확인 (active/disabled_manually/disabled_inactivity)
GET /repos/{owner}/{repo}/actions/workflows
```

### 일괄 비활성화
```python
PUT /repos/{owner}/{repo}/actions/permissions
Body: {"enabled": false}
# Response: HTTP 204 No Content
```

> 응답 본문 없음. 검증은 동일 엔드포인트 GET으로 `{"enabled": false}` 확인.

---

## 7. 향후 권장 사항

1. **Fork 생성 시 즉시 Actions OFF**: 새로 fork 뜰 때마다 Settings → Actions → Disable 설정 → 알림 폭탄 사전 차단
2. **GitHub Notifications 필터링**: `is:unread reason:ci-activity` 등의 필터로 CI 알림만 따로 처리
3. **정기 점검**: 본 스크립트를 GitNote의 `CodeSnippets/`에 등록해두면 분기별 재실행 가능
4. **카테고리 D 정리**: 2023년 이전 fork들은 가치 없음 가능성 높음, 한 번에 삭제 권장

---

## 8. 참고

- 본 점검은 4-surface 연계 원칙 중 `GitNote` surface에 기록됨
- Profile README(`Juwon1405/Juwon1405`)에는 영향 없음
- GitHub Pages(`juwon1405.github.io`)에는 영향 없음
- agentic-dart(SANS 제출작)에는 영향 없음

---

**작성자:** 구실장 (Claude / 유신님 비서)
**검증:** 2026-05-12 22:35 JST 기준 모든 처리 HTTP 204 / 200 응답 확인
