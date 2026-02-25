# CRAM Harness Plugin

**CRAM(Cache-Robust Architecture Memory)** 하네스 플러그인입니다.  
에이전트의 전역 행동 규칙을 프로젝트에 자동 주입하고, 작업 완료 시 에피소딕 메모리를 구조화된 포맷으로 기록합니다.

- **외부 스크립트 0개** — 모든 로직이 커맨드 마크다운 안에 인라인으로 포함
- **의존성 최소** — Python3만 필요 (macOS 기본 탑재)
- **크로스 플랫폼** — macOS, Linux, WSL 지원

## 플러그인 구조

```
cram-harness-plugin/
├── .claude-plugin/
│   └── plugin.json              # 플러그인 매니페스트 (v1.0.0)
├── commands/
│   ├── setup.md                 # /cram-harness:setup
│   └── commit-plan.md           # /cram-harness:commit-plan
└── README.md
```

## 설치 방법

### CLI 설치

```
/plugin marketplace add <your-org>/cram-harness-plugin
/plugin install cram-harness
```

### Agent SDK (Python)

```python
from claude_agent_sdk import query

async for message in query(
    prompt="Hello",
    options={
        "plugins": [
            {"type": "local", "path": "./cram-harness-plugin"}
        ]
    }
):
    pass
```

## 사용법

### 1. 프로젝트 초기화: `/cram-harness:setup`

새 프로젝트 디렉토리에서 실행합니다. 에이전트가 다음을 자동으로 수행합니다:

1. **Git 저장소 검증** — 비-Git 디렉토리면 경고 출력 (중단하지 않음)
2. **디렉토리 생성** — `rules/`, `memory/drafts/`, `plans/`, `.harness_data/fine_tuning/`
3. **파일 생성** — `rules/MAP.md`, `memory/MEMORY.md`
4. **CLAUDE.md 전역 규칙 주입** — 4대 원칙 + CRAM 운영 스펙을 프로젝트 `CLAUDE.md`에 하드코딩

생성된 `CLAUDE.md`에 포함되는 규칙:

| 구분 | 내용 |
|------|------|
| 4대 원칙 | YAGNI, DIP, WWHP, OSL |
| 금지 패턴 | No Tool Shuffling, 가변 정보 포함 금지, 모델 교체 금지 |
| Linter 룰 | Git 커밋 전 자가 검열 (Self-Correction) |
| Plan Mode | 프리픽스 유지를 위한 Read-only 모드 |
| 컴팩션 | 컨텍스트 80% 시 5줄 요약 + `/compact` |
| system-reminder | `[CATEGORY] {주제} \| [INFO] {내용}` 포맷 |

### 2. 에피소딕 메모리 기록: `/cram-harness:commit-plan`

작업을 마친 뒤 실행합니다. 에이전트가 다음을 수행합니다:

1. **질문** — 도메인(DOMAIN), 핵심 의도(WHY), 폐기된 접근법(FAILED)을 묻습니다
2. **기록** — 인라인 Python3 코드로 두 곳에 동시 기록:
   - `memory/MEMORY.md` — 사람이 읽기 좋은 마크다운 포맷
   - `.harness_data/fine_tuning/experiences.jsonl` — 파인튜닝용 JSONL
3. **완료 알림** — 기록된 커밋 해시와 함께 플랜 종료를 알립니다

**기록 포맷 예시:**

```markdown
# memory/MEMORY.md
- [2026-02-25] [DOMAIN: auth] -> [COMMIT: a1b2c3d]
  - [WHAT] OAuth2 리프레시 토큰 자동 갱신 구현
  - [WHY] 사용자 세션 만료 시 재로그인 UX 개선
  - [FAILED] Redis TTL 기반 갱신 → 분산 환경에서 동기화 불가
```

```json
// .harness_data/fine_tuning/experiences.jsonl (한 줄)
{"date": "2026-02-25", "domain": "auth", "commit": "a1b2c3d", "what": "OAuth2 리프레시 토큰 자동 갱신 구현", "why": "사용자 세션 만료 시 재로그인 UX 개선", "failed": "Redis TTL 기반 갱신 → 분산 환경에서 동기화 불가"}
```

## 왜 skills/를 안 쓰나요?

Claude Code SDK에서 `skills/`는 에이전트가 **필요할 때 능동적으로 호출하는 온디맨드 도구**(예: DB 조회, API 호출)를 위한 디렉토리입니다. YAGNI, DIP 같은 **전역 행동 강령**을 `skills/`에 넣으면, 에이전트가 해당 스킬을 호출하지 않는 한 규칙을 전혀 인지하지 못합니다.

따라서 전역 규칙은 프로젝트의 `CLAUDE.md`에 직접 주입하여, 프로젝트를 열 때마다 에이전트가 **무조건** 읽도록 하는 것이 정답입니다.

## 의존성

| 도구 | 용도 | 설치 |
|------|------|------|
| Python3 | JSONL 생성 (에피소딕 메모리) | macOS: 기본 탑재 / Linux: `apt install python3` |
| Git | 커밋 해시 추출 (선택) | 미설치 시 `uncommitted`으로 대체 |

## 라이선스

MIT
