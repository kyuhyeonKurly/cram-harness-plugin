---
description: "현재 플랜을 종료하고 에피소딕 메모리를 3-Phase 파이프라인으로 기록합니다."
---

# /cram-harness:commit-plan — Layer 7 에피소딕 메모리 커밋

이 명령어가 실행되면 너는 다음 작업을 **순서대로** 수행해야 해:

---

## 1단계: 사용자에게 질문

사용자에게 아래 4가지를 짧게 물어본다:

1. **도메인(DOMAIN)**: 방금 작업한 영역은? (예: `auth`, `payment`, `infra`, `docs` 등)
2. **핵심 의도(WHY)**: 왜 이 작업을 했나?
3. **폐기된 접근법(FAILED)**: 시도했지만 버린 방법이 있었나? (없으면 "없음")
4. **장애 등급(SEVERITY)**: 이 작업의 임팩트는? (`SEV-1` | `SEV-2` | `SEV-3` | `none`, 기본값: `none`)

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

## 3단계: 에피소딕 메모리 기록 (3-Phase Pipeline)

사용자의 답변을 받은 뒤, 아래 Python3 스크립트를 실행한다. **반드시 이 코드를 그대로 사용**하고 포맷을 변경하지 마라:

```bash
python3 -c "
import json, subprocess, datetime, os, sys, hashlib

# ── 입력값 ──
DOMAIN   = sys.argv[1]
WHAT     = sys.argv[2]
WHY      = sys.argv[3]
FAILED   = sys.argv[4]
SEVERITY = sys.argv[5] if len(sys.argv) > 5 else 'none'

# ── 메타데이터 수집 ──
NOW  = datetime.datetime.now(datetime.timezone.utc)
DATE = NOW.strftime('%Y-%m-%d')
TS   = NOW.isoformat()

# Git 메타데이터
try:
    COMMIT = subprocess.check_output(
        ['git', 'rev-parse', '--short', 'HEAD'],
        stderr=subprocess.DEVNULL
    ).decode().strip()
except Exception:
    COMMIT = 'uncommitted'

try:
    BRANCH = subprocess.check_output(
        ['git', 'rev-parse', '--abbrev-ref', 'HEAD'],
        stderr=subprocess.DEVNULL
    ).decode().strip()
except Exception:
    BRANCH = 'unknown'

# 에피소드 고유 ID (SHA256 첫 12자)
raw = f'{TS}|{DOMAIN}|{COMMIT}|{WHAT}'
EPISODE_ID = hashlib.sha256(raw.encode()).hexdigest()[:12]

# ══════════════════════════════════════════════
# Phase 1: 에피소딕 메모리 적재 (즉시 실행)
# ══════════════════════════════════════════════

# 1-A) memory/MEMORY.md — 사람이 읽기 좋은 포맷으로 Append
os.makedirs('memory', exist_ok=True)
with open('memory/MEMORY.md', 'a', encoding='utf-8') as f:
    f.write(f'\n- [{DATE}] [{EPISODE_ID}] [DOMAIN: {DOMAIN}] -> [COMMIT: {COMMIT}] ({BRANCH})\n')
    f.write(f'  - [WHAT] {WHAT}\n')
    f.write(f'  - [WHY] {WHY}\n')
    f.write(f'  - [FAILED] {FAILED}\n')
    if SEVERITY != 'none':
        f.write(f'  - [SEVERITY] {SEVERITY}\n')

# 1-B) .harness_data/fine_tuning/experiences.jsonl — 파인튜닝용 JSONL Append
os.makedirs('.harness_data/fine_tuning', exist_ok=True)
record = {
    'episode_id': EPISODE_ID,
    'timestamp': TS,
    'date': DATE,
    'domain': DOMAIN,
    'branch': BRANCH,
    'commit': COMMIT,
    'what': WHAT,
    'why': WHY,
    'failed': FAILED,
    'severity': SEVERITY
}
with open('.harness_data/fine_tuning/experiences.jsonl', 'a', encoding='utf-8') as f:
    f.write(json.dumps(record, ensure_ascii=False) + '\n')

# 1-C) .harness_data/rag_db/postmortem.yaml — RAG 검색용 YAML Append
os.makedirs('.harness_data/rag_db', exist_ok=True)
with open('.harness_data/rag_db/postmortem.yaml', 'a', encoding='utf-8') as f:
    f.write(f'---\n')
    f.write(f'episode_id: {EPISODE_ID}\n')
    f.write(f'timestamp: {TS}\n')
    f.write(f'domain: {DOMAIN}\n')
    f.write(f'branch: {BRANCH}\n')
    f.write(f'commit: {COMMIT}\n')
    f.write(f'severity: {SEVERITY}\n')
    f.write(f'what: \"{WHAT}\"\n')
    f.write(f'why: \"{WHY}\"\n')
    f.write(f'failed: \"{FAILED}\"\n')

print(f'\n✅ Layer 7 에피소딕 메모리 적재 완료! (episode: {EPISODE_ID})')
print(f'   Phase 1 ✓  MEMORY.md + JSONL + YAML')

# ══════════════════════════════════════════════
# Phase 2: 패턴 분석 (TODO — 향후 구현)
# ══════════════════════════════════════════════
# - experiences.jsonl을 주기적으로 읽어 도메인별 실패 패턴 집계
# - 반복 실패 도메인 자동 경고 (예: auth 도메인 3회 연속 실패)
# - rules/MAP.md 자동 업데이트 제안

# ══════════════════════════════════════════════
# Phase 3: 파인튜닝 데이터셋 변환 (TODO — 향후 구현)
# ══════════════════════════════════════════════
# - experiences.jsonl → OpenAI fine-tuning JSONL 포맷 변환
# - system/user/assistant 턴 자동 생성
# - 도메인별 필터링 및 품질 점수 산출
" "DOMAIN_VALUE" "WHAT_VALUE" "WHY_VALUE" "FAILED_VALUE" "SEVERITY_VALUE"
```

**인자 매핑 규칙** (사용자의 답변을 아래 위치에 대입):
- `DOMAIN_VALUE` → 사용자가 답한 도메인명
- `WHAT_VALUE` → 방금 수행한 작업 요약 (너가 세션 컨텍스트에서 자동 생성)
- `WHY_VALUE` → 사용자가 답한 핵심 의도
- `FAILED_VALUE` → 사용자가 답한 폐기된 접근법 (없으면 `"없음"`)
- `SEVERITY_VALUE` → 사용자가 답한 장애 등급 (없으면 `"none"`)

---

## 4단계: 완료 보고

스크립트 실행이 성공하면 아래 메시지를 출력한다:

> ✅ 플랜이 성공적으로 종료되었습니다!
>
> **Phase 1 적재 완료:**
> | 출력 | 경로 | 용도 |
> |------|------|------|
> | MEMORY.md | `memory/MEMORY.md` | 사람 읽기용 에피소딕 메모리 |
> | JSONL | `.harness_data/fine_tuning/experiences.jsonl` | 파인튜닝 텔레메트리 |
> | YAML | `.harness_data/rag_db/postmortem.yaml` | RAG 검색용 포스트모템 |
>
> 에피소드 ID: `{EPISODE_ID}` · 커밋: `{COMMIT}` · 브랜치: `{BRANCH}`
