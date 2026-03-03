---
description: "프로젝트 구조를 자동 분석하여 도메인 라우팅 맵(MAP.md)을 생성하거나 업데이트합니다."
---

# /cram-harness:map — 도메인 라우팅 맵 관리

이 명령어가 실행되면 너는 다음 작업을 **순서대로** 수행해야 해:

---

## MAP.md 표준 스키마

이 커맨드가 생성·유지하는 포맷은 다음과 같다. `commit-plan`의 DOMAIN 추론이 "키워드 ↔ 도메인" 테이블을 파싱할 수 있도록 이 형식을 반드시 준수한다:

```markdown
# 🗺️ Project Knowledge Map (Domain Routing)

<!-- CRAM Harness 자동 생성 | 마지막 업데이트: {DATE} -->

## Domain Routing Table

| 도메인 | 키워드 | 파일 패턴 | 설명 |
|--------|--------|----------|------|
| auth   | oauth, jwt, session, token, login | `src/auth/`, `*auth*`, `*login*` | 인증/인가 |
| api    | rest, endpoint, controller, route | `src/api/`, `routes/`            | API 레이어 |
```

---

## 1단계: 상태 감지

`.cram-harness/rules/MAP.md` 파일을 읽어 상태를 판별한다:

- **Draft 모드**: 파일이 없거나, 도메인 테이블 행(파이프 구분 테이블 내 실제 데이터 행)이 0개인 경우
- **Update 모드**: 도메인 테이블 행이 1개 이상 존재하는 경우

판별 결과에 따라 2단계 분기로 이동한다.

---

## 2단계 (Draft 모드): 프로젝트 구조 자동 분석

아래 정보를 수집하여 도메인 목록을 추론한다:

```bash
# 1. 디렉토리 트리 (숨김/무거운 빌드·환경 폴더 제외)
find . -maxdepth 4 -type d \
  -not -path '*/\.*' \
  -not -path '*/node_modules/*' \
  -not -path '*/dist/*' \
  -not -path '*/build/*' \
  -not -path '*/venv/*' \
  -not -path '*/.env/*' \
  -not -path '*/.next/*' \
  -not -path '*/Pods/*' \
  -not -path '*/__pycache__/*' \
  -not -path '*/target/*'

# 2. 기술 스택 마커 파일 감지
ls package.json requirements.txt go.mod Cargo.toml pom.xml build.gradle 2>/dev/null

# 3. 프로젝트 CLAUDE.md 읽기 (도메인 힌트)
cat CLAUDE.md 2>/dev/null
```

수집된 디렉토리 구조 + CLAUDE.md 설명 + 기술 스택을 종합하여, **에이전트가 직접 도메인 테이블을 추론**하고 MAP.md 전체 초안을 생성한다.

도메인 추론 기준:
- 디렉토리명이 도메인을 직접 암시하는 경우 (예: `src/auth/`, `src/payment/`, `api/users/`)
- 기술 스택 마커가 특정 도메인과 연관되는 경우 (예: `requirements.txt` → Python/ML 스택)
- CLAUDE.md에 도메인 언급이 있는 경우

**공통 도메인 패턴 참고** (프로젝트에 맞게 조정):

| 도메인 | 일반 키워드 | 일반 파일 패턴 |
|--------|-------------|----------------|
| auth | oauth, jwt, session, token, login, logout, signup | `src/auth/`, `*auth*`, `*login*`, `*session*` |
| api | rest, endpoint, controller, route, handler | `src/api/`, `routes/`, `controllers/`, `handlers/` |
| db | database, model, schema, migration, query, orm | `src/db/`, `models/`, `migrations/`, `*schema*` |
| ui | component, view, page, layout, style, css | `src/ui/`, `components/`, `pages/`, `views/` |
| config | env, settings, configuration, deploy, ci | `config/`, `.env*`, `*config*`, `*settings*` |
| test | spec, test, mock, fixture, e2e | `test/`, `tests/`, `__tests__/`, `spec/` |

---

## 2단계 (Update 모드): 변경사항 분석

```bash
# 최근 10커밋에서 변경된 파일 목록
git log --oneline -10 --name-only 2>/dev/null
```

현재 MAP.md를 읽고, 최근 변경 파일 + 세션 컨텍스트를 분석하여:
- 기존 테이블에 없는 새 도메인/키워드만 추출
- 기존 행을 수정하거나 새 행을 추가할 항목을 제안

---

## 3단계: 실행 모드 판별 (Normal vs Turbo)

`commit-plan`과 동일한 Turbo 트리거 키워드 체계를 사용한다:

**트리거 단어 목록** (하나라도 포함되면 Turbo 모드):
- 한국어: `"알아서"`, `"원스톱"`, `"자동으로"`, `"자동"`, `"한 번에"`, `"바로"`, `"즉시"`, `"지시대로"`
- 영어: `"autopilot"`, `"auto"`, `"one-stop"`, `"just do it"`

### Turbo 모드 (트리거 감지됨)

확인 절차 **없이** 즉시 4단계(MAP.md 작성)를 실행한다.

### Normal 모드 (트리거 미감지)

추론된 도메인 테이블을 먼저 출력한다:

> 🗺️ **추론된 도메인 라우팅 테이블**
>
> | 도메인 | 키워드 | 파일 패턴 | 설명 |
> |--------|--------|----------|------|
> | auth   | oauth, jwt, session | `src/auth/`, `*auth*` | 인증/인가 |
> | ...    | ...    | ...       | ...  |
>
> 이대로 MAP.md에 기록할까요?

사용자가 승인하면 4단계로 진행한다. 수정 요청 시 해당 행만 교체 후 진행한다.

---

## 4단계: MAP.md 작성

### Draft 모드

`.cram-harness/rules/MAP.md`를 표준 스키마로 **전체 작성(덮어쓰기)**한다.

작성 형식 (오늘 날짜를 `{DATE}` 위치에 삽입):

```markdown
# 🗺️ Project Knowledge Map (Domain Routing)

<!-- CRAM Harness 자동 생성 | 마지막 업데이트: {DATE} -->

## Domain Routing Table

| 도메인 | 키워드 | 파일 패턴 | 설명 |
|--------|--------|----------|------|
| {domain1} | {keywords} | {patterns} | {desc} |
| {domain2} | {keywords} | {patterns} | {desc} |
```

### Update 모드

단순 append **금지**. 아래 절차를 반드시 따른다:

1. 기존 MAP.md 전체를 읽는다.
2. git log 컨텍스트와 세션 컨텍스트를 함께 분석한다.
3. 신규 도메인을 기존 테이블에 **병합(Merge)**한다.
4. 테이블 전체를 재작성(Rewrite)하여 파일을 덮어쓴다.
   - 파이프(`|`) 정렬 유지
   - 중복 행 방지
   - `마지막 업데이트:` 날짜 갱신

---

## 5단계: 완료 보고

MAP.md 작성이 완료되면 아래 형식으로 보고한다:

```
✅ 도메인 라우팅 맵 [초안 생성 | 업데이트] 완료!

| 도메인 | 키워드 수 | 파일 패턴 수 |
|--------|----------|-------------|
| auth   | 5        | 3           |
| ...    | ...      | ...         |

→ .cram-harness/rules/MAP.md 저장 완료
→ 이제 /cram-harness:commit-plan 실행 시 DOMAIN이 자동으로 정확하게 추론됩니다.
```
