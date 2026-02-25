#!/bin/bash
# 이 스크립트는 프로젝트 경로에서 CRAM 뼈대 파일을 생성합니다.
echo "🚀 CRAM Harness V2 초기화를 시작합니다..."
mkdir -p rules memory/drafts plans .harness_data/fine_tuning
echo "# 프로젝트 아키텍처 & 도메인" > CLAUDE.md
echo "# 🗺️ Project Knowledge Map (Domain Routing)" > rules/MAP.md
echo "# Episodic Memory Log" > memory/MEMORY.md
echo "✅ CRAM 로컬 세팅 완료!"
