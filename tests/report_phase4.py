"""Summarize saved Godot measurements; refuse incomplete comparison runs."""
from pathlib import Path
import hashlib
import json
import sys

sys.stdout.reconfigure(encoding='utf-8')
root = Path(__file__).resolve().parents[1]
read = lambda name: json.loads((root / 'docs' / name).read_text(encoding='utf-8'))
baseline = read('baseline/phase3-balance-results.json')
result = read('phase4-balance-results.json')
probabilities = read('phase4-probabilities.json')
fire_rates = read('phase4-fire-rates.json')
assert probabilities['draws'] >= 1_000_000 and probabilities['failures'] == 0
assert fire_rates['failures'] == 0
for key in ('random', 'weak', 'strong'):
    group = result['cohorts'][key]
    assert group['summary']['runs'] == 100 and len(group['runs']) == 100, '100-seed run unfinished'
    assert {r['seed'] for r in group['runs']} == set(range(1, 101))
    for row in group['runs']:
        assert row['game_over'] or row['wave'] == 14, 'Truncated simulation'
        if row['game_over']:
            assert row['samples'][str(row['wave'])]['alive'] == 60

names = {'random': '4차 무작위 유형·등급', 'weak': '일반 ASSAULT 2기 시작', 'strong': '일반 SIEGE + LANCER 시작'}
lines = ['# 4차 실제 검증 결과', '',
         'Godot4.4.1 실제 Session/Enemy/Combat 구현을60Hz로 호출. 몬스터/웨이브/경제 데이터는3차와 동일.',
         '시드1~100, 50G마다 고정 순서로 즉시 소환, 이동/판매 없음, 13웨이브 종료까지 관측.',
         '무작위/약한 초기/강한 초기 각100회 + 무성장 대조2회 + 전설 단독7회 = 총309회.',
         '3차는 보존된 원시 기록에서 읽었다. 같은 시드 번호/전략을 사용하지만4차는 등급 추첨이 추가되어 동일한 유형 추첨열은 아니다. 전체 버전 변화 비교이며 등급만의 인과 효과를 분리한 실험은 아니다.',
         '', '| 버전/초기 조건 | 표본 | 4웨이브 이내 패배 | 10웨이브 도달 | 실제 패배 수 |', '|---|---:|---:|---:|---:|']
def summary_line(label, stat):
    return f"| {label} | {stat['runs']} | {stat['death_by_wave4_pct']:.1f}% | {stat['reach_wave10_pct']:.1f}% | {stat['actual_game_overs']} |"
lines.append(summary_line('3차 무작위(저장된 기준)', baseline['cohorts']['random']['summary']))
for key, label in names.items():
    lines.append(summary_line(label, result['cohorts'][key]['summary']))
lines += ['', '실제 패배 수는13웨이브까지의 관측값이다. 살아서14웨이브에 진입한 시행의 이후 결과는 알 수 없다. 사람 플레이 승률이 아닌 이 자동 정책의 결과다.',
          '', '## 전설 한 기 대조군', '',
          '전설1기 외에는 소환·이동·판매하지 않는 결정론적 실험. 각 유형1회이며, 모집단 승률을 추정하지 않는다.', '',
          '| 전설 유형 | 종료 웨이브 | 실제 패배 |', '|---|---:|---|']
for key, group in result['cohorts'].items():
    if key.startswith('legendary_solo_'):
        row = group['runs'][0]
        lines.append(f"| {key.removeprefix('legendary_solo_')} | {row['wave']} | {'예' if row['game_over'] else '관측 구간 생존'} |")
lines += ['', '## 100만 회 추첨', '', '고정시드20261120. 10000개 정수 티켓 전 구간에서6000/2600/1000/350/50개를 정확히 배정하는 경계 검사도 통과했다.',
          '', '| 등급 | 설정 확률 | 실제 횟수 | 관측 비율 |', '|---|---:|---:|---:|']
for name, expected in [('COMMON', 60), ('UNCOMMON', 26), ('RARE', 10), ('EPIC', 3.5), ('LEGENDARY', 0.5)]:
    count = probabilities['grade_counts'][name]
    lines.append(f'| {name} | {expected}% | {count:,} | {count / probabilities["draws"] * 100:.4f}% |')
lines += ['', '7종 유형 분포와35개 유형×등급 결합 분포도 이항 표준편차7배 허용구간 내 검증했다. 표본빈도가 설정값과 정확히 같아야 하는 것은 아니다. 희귀 확률을 소수의 수동 소환으로 판단하지 않았다.',
          '', '## 실제 공격 주기 검사', '',
          '60초 연속 사격/고정 표적. 프레임 소수 잔여 시간을 보존하여 등급 공격속도 보너스가 실제 발사 횟수에 반영되도록 수정했다. 표적 없는 시간의 공격 부채는 누적하지 않는다.',
          '', '| 등급 | 기대 초당 발사 | 실제 초당 발사 |', '|---|---:|---:|']
for row in fire_rates['measurements']:
    lines.append(f"| {row['grade']} | {row['expected_shots_per_second']:.4f} | {row['actual_shots_per_second']:.4f} |")

lines += ['', '## 웨이브별 골드와 누적', '', '웨이브 종료 직전(다음 보급 전) 또는 패배 시점 측정. 해당 웨이브에 도달한 표본만 포함하며, 패배의 생존 적 수는60이다. 후반 표본수가 줄어드는 점에 유의한다.']
for key, label in names.items():
    lines += ['', f'### {label}', '', '| 웨이브 | 표본 | 평균 잔여 골드 | 평균 생존 적 |', '|---|---:|---:|---:|']
    for wave, row in sorted(result['cohorts'][key]['per_wave'].items(), key=lambda item: int(item[0])):
        lines.append(f"| {wave} | {row['n']} | {row['mean_gold']:.2f}G | {row['mean_alive']:.2f} |")
lines += ['', '## 경제/해석', '',
          '- 초기100G/소환50G/판매25G/준비10초/생존 적60기 패배 유지. 등급별 판매 프리미엄 없음.',
          '- 적 보상·웨이브 공급이 그대로이므로13웨이브까지 가능한 누적 수입 상한은 지출 전 초기 포함1452G다. 등급은 별도의 골드를 생성하지 않는다.',
          '- 초기 조합 비교군은 두 유닛을 일반 등급으로 고정하고 이후 유형·등급은 정상 추첨한다. weak는4차 ASSAULT2로서3차 VULCAN2와 직접 같은 조건은 아니다.',
          '- 고정 배치는 화염의 짧은 사거리나 전자전의 위치 최적화를 하지 않는다. 수동 이동/판매/재추첨 전략은 별도 플레이 테스트 영역이다.',
          '- 시뮬레이션은 상태효과로 사망한 적이 배열에서 제거되는 경우도 안전하게 반영하도록 이동 대상 스냅샷을 순회한다.',
          '', '## 재현', '', '```powershell', '.\\run.ps1 -Test', '.\\run.ps1 -WindowsTest', '.\\run.ps1 -Balance', 'python tests/report_phase4.py', '```', '',
          f"최종 시뮬레이션 소요: {result['seconds']:.2f}초. 원시 자료: phase4-balance-results.json, phase4-probabilities.json, phase4-fire-rates.json.",
          '', '### 검증 시점 SHA-256', '']
paths = ['scripts/core/combat.gd', 'scripts/core/game_session.gd', 'scripts/entities/enemy.gd', 'scripts/entities/tower.gd', 'tests/balance_simulation.gd', 'data/waves.tres', 'data/unit_catalog.tres', 'data/grade_catalog.tres']
paths += [str(p.relative_to(root)).replace('\\', '/') for folder in ['units', 'grades', 'enemies'] for p in (root/'data'/folder).glob('*.tres')]
for path in paths:
    lines.append(f'- `{path}`: `{hashlib.sha256((root/path).read_bytes()).hexdigest()}`')
(root/'docs/PHASE4_RESULTS.md').write_text('\n'.join(lines)+'\n', encoding='utf-8')
print('\n'.join(lines[:18]))
print('Saved docs/PHASE4_RESULTS.md')
