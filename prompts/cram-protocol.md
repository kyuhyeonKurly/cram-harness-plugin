# CRAM Protocol — 상세 운영 스펙
## Linter 에이전트 룰 (Self-Correction)
- Git 커밋 직전, 결과물이 `CLAUDE.md`의 원칙(YAGNI, DIP)과 프로젝트 `rules/`에 위배되지 않는지 자가 검열해야 한다. 위배 시 계획을 수정한다.

## Cache-Safe Forking & Plan Mode
- Plan Mode 진입 시 프리픽스 유지를 위해 파일 수정을 금지한다.
