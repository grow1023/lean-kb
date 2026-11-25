# Changelog

이 프로젝트의 주요 변경 사항을 기록합니다.
형식: [Keep a Changelog](https://keepachangelog.com/), 버전: [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added
- UserPromptSubmit 훅(`hooks/lean_kb_hook.py`)과 훅 자체 시험
- 규칙 노트(`rules/lean-kb.md`)와 근거 표가 있는 `SKILL.md`
- 수치 대조 도구(`scripts/check_numbers.py`)와 마스터 게이트(`gates/verify_lean_kb.sh`)
- 영어, 한국어, 일본어, 중국어 README

### Fixed
- 수치 대조 도구가 버전 문자열(예: 0.1.0)을 측정 수치로 읽던 문제
- 호스트가 붙이는 알림 블록 안의 단어에 훅이 반응하던 문제
- 독립 검토에서 나온 문서 보정: 규칙 2의 시험 조건, 규칙 7의 상태, 끄기 조건, 키워드 일치 설명

[Unreleased]: https://github.com/grow1023/lean-kb/commits/main
