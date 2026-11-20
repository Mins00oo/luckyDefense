# 3차 검증 기록

## 실제 실행

- Windows / Godot4.4.1 / Intel Iris Xe / Compatibility(OpenGL3.3).
- Phase1 공격·경제·루프 테스트, Phase2 준비·이동·교환·판매 테스트 통과.
- Phase3: 3바퀴 순환 이후 생존, 웨이브 전환 이후 생존, 생존 보급 중복 방지, 방어력, 타입별 이동 차이, 1~20웨이브 출현 시간이18초 이내인지, 정확히60기 패배/추가 생성 차단 검사 통과.
- 실제 Viewport 입력으로 선택 유닛 재클릭, 우클릭, HUD 빈 배경 클릭, ESC, 기존 이동·판매·재시작 검사 통과.
- headless가 아닌 Windows 창에서 10초 준비 → 첫 웨이브(관측9.926초; 물리 프레임 경계 포함), 이동 후 전투, 판매 UI, 재시작 검사 통과.
- 정적 독립 리뷰에서 중요한 문제 없음.

## 밸런스

`balance-results.json`은 총302회 실제 GDScript 실행 결과다. 자세한 집계 및 표본수는 `PHASE3_RESULTS.md` 참고.
전체 실행277.172초. 원시 결과에 각 시드/초기 조합/종료 웨이브/실제 패배/잔여 골드/처치/유닛 수/웨이브별 관측치를 보관했다.
무성장 결정론 대조군은 벌컨2가4웨이브, 시즈+랜서가5웨이브에서 실제 누적 패배했다.
고정 사거리 단일 대상60초 DPS는 `measure_dps.gd`로 실측하여 `dps-results.json`에 저장했다.

## 밀집 상태 성능과 화면

실제 Windows 렌더러에서 **적59기 + 포탑24기**의 이동/타깃 탐색/피해 판정/공격 이펙트를 실행했다.
이 검증은 사망 없이 부하를 유지하기 위해 적 체력을 테스트에서만 크게 설정한 fixture이며 밸런스 실험 결과와 구분한다.
2초 워밍업 뒤3초 측정:180프레임, physics 평균1.683ms / 최대1.992ms, 프레임 간격95백분위20.66ms.
이펙트13개(상한128), 적59기 유지 확인 후60번째 적을 생성해 실제 패배 전환도 확인했다.
숫자는 해당 PC의 짧은 측정이며 iPhone/장시간 성능을 보장하지 않는다. 초기 로딩 포함 수치는 제외했다.
원시 성능값 `phase3-performance.json`, 화면 `phase3-pressure.png`.

성능 관리: 동시 적60기/포탑24기 한도, 시각 이펙트128개 상한, 체력바 피격 시에만 다시 그리기, 사망 적 배열에서 즉시 제외. 공격 탐색은 쿨다운이 끝난 포탑만 수행한다.

## 주요 변경 파일

- `scripts/data/enemy_definition.gd`, `data/enemies/*.tres`: 네 적 타입의 전투/보상/그래픽 데이터.
- `scripts/data/wave_director.gd`, `data/waves.tres`: 편성/간격/성장/웨이브 보급.
- `scripts/entities/enemy.gd`, `scenes/enemy.tscn`, `scenes/enemy_visual.tscn`, `scripts/visuals/enemy_visual.gd`: 적 데이터 적용, 방어력, 교체 가능한 시각 씬.
- `scripts/core/game_session.gd`: 혼합 타입 출현, 생존 보급, 재클릭 선택 해제.
- `scripts/core/board.gd`, `scripts/ui/hud.gd`: 해제 입력, 생존 수/누적 경고/적 범례.
- `scripts/visuals/effects.gd`: 효과 수 상한.
- `tests/test_phase3.gd`, `tests/balance_simulation.gd`, `tests/measure_dps.gd`, `tests/test_phase3_windows.gd`, `tests/report_balance.py`, 기존 입력 테스트, `run.ps1`, README 및 보고서.

유닛 능력치·종류·등급·가중치와 기존 자동 공격 알고리즘은 변경하지 않았다.
초기100G / 소환50G / 판매25G / 준비10초를 유지한다.
