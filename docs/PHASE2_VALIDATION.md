# 2차 검증 결과 — 2026-11-20

Godot 4.4.1 stable / Windows / Intel Iris Xe / OpenGL 3.3 Compatibility.

## 통과한 테스트

- `tests/test_phase2.gd`: 준비 10초, 초기 100G, 소환 50G, 준비 중 적/웨이브 타이머 정지, 준비 일시정지/재개, 무소환 첫 웨이브, 선택 표시, 빈 슬롯 이동, 점유 슬롯 교환, 무료 이동과 쿨다운 보존, 전투 중 이동 및 새 위치 기준 자동 공격.
- 판매 요청/취소/확정, 25G 환불, 중복 확정 무효, 판매 슬롯 재소환, 선택 해제/일시정지/재시작으로 확인 무효화, 재시작 월드 초기화 통과.
- `tests/test_loop.gd`: 기존 3종 공격, 범위 밖 적 보호, 소환 분포, 자금 부족/슬롯 포화, 처치 보상 1회, 경로 순환, 패배/재시작 회귀 검사 통과.
- `tests/test_input.gd`: Viewport 마우스/키보드 이벤트로 소환, Space 일시정지, 재개, 재시작 통과.
- `tests/test_simulation.gd`: 준비 포함 90초, 5웨이브 / 73처치 / 17포탑 / 잔여 적 0. 고정 시드, 60 FPS 시뮬레이션.
- `tests/test_phase2_windows.gd`: **headless가 아닌 실제 Windows OpenGL 창**에서 자동 입력으로 준비 중 소환·선택·이동·교환·판매 취소·판매 확정·HUD 환불·재소환·ESC·전투 중 이동·재시작 통과. 고정 FPS/시간 가속 없이 준비 → 첫 웨이브 전환 측정 약 10초(관측값 9.957초, 엔진 물리 프레임 경계 차이 포함). 이후 실제 적 이동과 공격/처치 확인.
- 모든 최종 실행 종료 코드 0, PHASE 2 / WINDOWS PHASE 2 각 0 failures. 별도 정적 코드 리뷰에서 중요한 문제 없음.

## 렌더링 확인

- `phase2-preparation.png`: 상단 작전 준비/남은 초, 선택 유닛 상세 및 사거리.
- `phase2-sale.png`: 기존 우측 HUD 안의 판매 확인·취소 버튼.
- `phase2-combat.png`: 이동된 유닛의 자동 공격, 적 이동, 처치 보상.
- 사거리 표시는 전장 영역에 클리핑되어 HUD 및 외곽 여백을 침범하지 않는다.

## 변경 파일

- `scripts/core/game_session.gd`: 단계/준비 타이머/경제/선택/이동/교환/판매 트랜잭션.
- `scripts/core/board.gd`: 슬롯 및 배경 클릭 전달, 선택/사거리 상태.
- `scripts/core/main.gd`: 준비 단계 재설정 시 잔여 공격 효과 정리.
- `scripts/entities/tower.gd`: 선택 외곽선.
- `scripts/visuals/range_display.gd` (신규), `scenes/main.tscn`: 클리핑된 사거리 표시.
- `scripts/ui/hud.gd`: 준비 시간, 상세정보, 판매 확인, 해제 버튼/ESC.
- `tests/test_phase2.gd`, `tests/test_phase2_windows.gd` 신규. 기존 테스트 4개는 새 상태/가격 규칙에 맞게 갱신.
- `run.ps1`, `README.md`, 2차 설계/검증 문서.

유닛 종류·능력치·가중치 데이터, CombatSystem 공격 공식, 몬스터 경로 및 난이도 수식은 수정하지 않음.
모바일은 기존 터치→마우스 에뮬레이션과 버튼 입력 구조를 유지. 실제 iPhone 터치 및 iOS 빌드는 미검증.

## 재현

```powershell
.\run.ps1 -Test
.\run.ps1 -WindowsTest
```

편집기에서는 기존 실행을 F8로 종료 후 F5로 다시 시작한다. 별도 시작 버튼 없이 준비 카운트다운이 시작된다.
