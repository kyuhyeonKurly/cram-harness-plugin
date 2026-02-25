---
description: "현재 플랜을 종료하고 에피소딕 메모리(WHAT, WHY, FAILED)를 기록합니다."
---

# /cram-harness:commit-plan — 에피소딕 메모리 커밋

이 명령어가 실행되면 너는 다음 작업을 **순서대로** 수행해야 해:

---

## 1단계: 사용자에게 질문

사용자에게 아래 3가지를 짧게 물어본다:

1. **도메인(DOMAIN)**: 방금 작업한 영역은? (예: `auth`, `payment`, `infra`, `docs` 등)
2. **핵심 의도(WHY)**: 왜 이 작업을 했나?
3. **폐기된 접근법(FAILED)**: 시도했지만 버린 방법이 있었나? (없으면 "없음")

---

## 2단계: Python3 사전 검증

아래 명령어를 실행하여 Python3가 설치되어 있는지 확인한다:

```bash
command -v python3
```

- **성공 시**: 3단계로 진행한다.
- **실패 시**: 아래 메시지를 출력하고 **중단**한다.

> ❌ Python3가 설치되어 있지 않습니다. 에피소딕 메모리 기록에 Python3가 필요합니다.
> - macOS: 기본 탑재 (확인: `python3 --version`)
> - Linux/WSL: `sudo apt install python3` 또는 `sudo yum install python3`

---

## 3단계: 에피소딕 메모리 기록

사용자의 답변을 받은 뒤, 아래 Python3 스크립트를 실행한다. **반드시 이 코드를 그대로 사용**하고 포맷을 변경하지 마라:

```bash
python3 -c "
import json, subprocess, datetime, os, sys

# 입력값
DOMAIN = sys.argv[1]
WHAT   = sys.argv[2]
WHY    = sys.argv[3]
FAILED = sys.argv[4]
DATE   = datetime.date.today().isoformat()

# Git 커밋 해시 (실패 시 uncommitted)
try:
    COMMIT = subprocess.check_output(
        ['git', 'rev-parse', '--short', 'HEAD'],
        stderr=subprocess.DEVNULL
    ).decode().strip()
except Exception:
    COMMIT = 'uncommitted'

# 1) memory/MEMORY.md — 사람이 읽기 좋은 포맷으로 Append
os.makedirs('memory', exist_ok=True)
with open('memory/MEMORY.md', 'a', encoding='utf-8') as f:
    f.write(f'\n- [{DATE}] [DOMAIN: {DOMAIN}] -> [COMMIT: {COMMIT}]\n')
    f.write(f'  - [WHAT] {WHAT}\n')
    f.write(f'  - [WHY] {WHY}\n')
    f.write(f'  - [FAILED] {FAILED}\n')

# 2) .harness_data/fine_tuning/experiences.jsonl — 기계가 읽기 좋은 JSONL Append
os.makedirs('.harness_data/fine_tuning', exist_ok=True)
record = {
    'date': DATE,
    'domain': DOMAIN,
    'commit': COMMIT,
    'what': WHAT,
    'why': WHY,
    'failed': FAILED
}
with open('.harness_data/fine_tuning/experiences.jsonl', 'a', encoding='utf-8') as f:
    f.write(json.dumps(record, ensure_ascii=False) + '\n')

print('✅ 에피소딕 메모리 및 JSONL 텔레메트리 적재 완료!')
" "DOMAIN_VALUE" "WHAT_VALUE" "WHY_VALUE" "FAILED_VALUE"
```

**인자 매핑 규칙** (사용자의 답변을 아래 위치에 대입):
- `DOMAIN_VALUE` → 사용자가 답한 도메인명
- `WHAT_VALUE` → 방금 수행한 작업 요약 (너가 세션 컨텍스트에서 자동 생성)
- `WHY_VALUE` → 사용자가 답한 핵심 의도
- `FAILED_VALUE` → 사용자가 답한 폐기된 접근법 (없으면 `"없음"`)

---

## 4단계: 완료 보고

스크립트 실행이 성공하면 아래 메시지를 출력한다:

> ✅ 플랜이 성공적으로 종료되었습니다!
>
> 기록 위치:
> - `memory/MEMORY.md` — 사람 읽기용 에피소딕 메모리
> - `.harness_data/fine_tuning/experiences.jsonl` — 파인튜닝용 JSONL 텔레메트리
>
> 기록된 커밋: `{COMMIT_HASH}`
