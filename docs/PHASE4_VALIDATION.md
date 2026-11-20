# 4차 변경 및 검증 기록

## 변경 파일

- `scripts/data/unit_definition.gd`: 유형/분류/7공격 방식/특수능력 필드.
- `scripts/data/unit_grade.gd`, `grade_catalog.gd` 신규: 독립 등급 및 정확한 정수 가중치 추첨.
- `data/units/*.tres`, `data/unit_catalog.tres`: 7종 유형과 가중치.
- `data/grades/*.tres`, `data/grade_catalog.tres` 신규: 5등급/확률/색/능력 배율.
- `scripts/entities/tower.gd`: 유형과 등급으로 유효 능력치 계산, 등급 마커.
- `scripts/entities/enemy.gd`: 출처별 연소/감속, 상한/만료/방어력 반영.
- `scripts/core/combat.gd`: 기존 공격 재사용, 저격 우선순위/관통, 원뿔 화염, 감속, 공격 주기 소수 잔여 보존.
- `scripts/core/game_session.gd`, `main.gd`: 유형+등급 소환 및 비차단 연출 신호, 재시작 정리.
- `scripts/visuals/tower_visual.gd`, `effects.gd`: 7실루엣, 유형별 공격 이펙트, 등급별 증원 연출.
- `scripts/ui/hud.gd`: 5등급 확률표, 선택 정보, 희귀 이상 알림.
- `tests/test_phase4.gd`, `test_probabilities.gd`, `test_fire_rate.gd`, `test_phase4_windows.gd`, `report_phase4.py` 신규.
- 기존 회귀 테스트·시뮬레이터·DPS 측정·run.ps1·README 확장.

## 기능 검증

- 7유형×5등급=35조합의 실제 Session 소환/이동/교환/판매. 등급과 관계없이25G 환불1회.
- 원본 유형 Resource를 등급 계산이 변경하지 않음. 범위/주기/특수효율도 차등 적용.
- 단일/광역/관통/원뿔/연소/감속 실제 CombatSystem 호출 및 비대상 보호.
- 저격수의 중장갑 우선 탐색과 방어6 관통 확인.
- 연소3출처 상한, 시간 간격과 무관한 누적 피해, 연소 사망 보상1회.
- 감속50% 상한, 강한 효과 만료 후 약한 효과 유지/만료, 일시정지 중 타이머 정지.
- 전체 확률100만회 및 정수 티켓10000개 전수 경계검사. 결과는 phase4-probabilities.json.
- 공격 주기 정밀도 문제를 실패 테스트로 재현한 뒤 수정. 등급별 실발사 속도와 무표적 대기 후 부채 방지 확인. phase4-fire-rates.json.
- 기존 준비10초/상태/경제/이동/판매/누적/60기 패배/선택 입력 회귀 검사 유지.

## Windows 시각 검증

Godot4.4.1 / Windows / Intel Iris Xe / OpenGL3.3 Compatibility에서 실제 창으로 실행.
`test_phase4_windows.gd`는 7종/여러 등급을 테스트 전용으로 배치하여 시각 확인하며 실제 소환 확률을 바꾸지 않는다.
전설 알림, 타입별 실루엣, 선택 패널, 화염·감속 정보, 비차단 소환 연출, 혼합 전투 및 재시작 효과 정리를 확인한다.
화면은 `phase4-silhouettes.png`, `phase4-roster.png`, `phase4-flame-info.png`, `phase4-drone-info.png`, `phase4-combat.png`.

## 비교 원칙

3차 원시 시드 통계를 docs/baseline에 보존하고4차 원시 결과는 별도 파일로 저장한다.
최종309회 비교와 웨이브별 표본수/평균 골드/생존 적, 전설 단독 결과는 PHASE4_RESULTS.md에 기록한다.
초기 고정 조합은 일반 ASSAULT2와 일반 SIEGE+LANCER이다. 이후 소환은 정상 유형·등급 추첨.
전설 단독 실험은 추가 소환/이동 없는 결정론 대조이며 전체 플레이 전략의 우월성을 증명하는 테스트가 아니다.

실제 iPhone, iOS export, 최종 픽셀아트/BGM은 이번 범위에 포함하지 않았다.

## 최종 실행 결과

- 전체 `run.ps1 -Test` 통과: 기존 회귀·입력·Phase2·Phase3·Phase4·연사 속도·100만회 확률·90초 자동 플레이. 오류0, 종료 코드0.
- 실제 Windows 준비부터 첫 웨이브 전환 관측9.909초, UI 이동/교환/판매/재시작0 failures.
- 실제 Windows 7종/5등급 시각 및 혼합 전투0 failures.
- 최종 밸런스309회, 실행785.414초. 무작위33% 조기 패배/37% 10웨이브 도달, 일반 ASSAULT2는77%/11%, 일반 SIEGE+LANCER는0%/81%.
- 전설 단독 무성장: VULCAN4, SIEGE8, LANCER5, ASSAULT4, MARKSMAN4, INCINERATOR5, DISRUPTOR4웨이브에서 실제 누적 패배. 강제 패배 코드는 없음.
- 적59기+포탑24기 Windows 밀집 fixture:2초 워밍업/3초 측정179프레임, physics 평균2.510ms/최대3.166ms, 프레임 간격95백분위22.507ms.60번째 적 생성 시 패배 전환 확인.
- 밀집 fixture는 적을 유지하려고 테스트에서만 큰 체력을 적용한 성능 검사이며 밸런스 통계와 구분한다. 원시 값 `phase4-performance.json`, 화면 `phase4-pressure.png`.
- 정적 코드 리뷰에서 발견한 공격 주기 반올림 문제를 실패 테스트로 재현해 수정했고, 재리뷰 통과. 수정 전 중단한 부분 시뮬레이션은 최종 결과에 포함하지 않음.
