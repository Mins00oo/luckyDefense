"""Turn actual Godot simulation output into reviewable tables; never synthesize runs."""
from pathlib import Path
import hashlib
import json
import sys

sys.stdout.reconfigure(encoding='utf-8')

ROOT = Path(__file__).resolve().parents[1]
result = json.loads((ROOT / 'docs/balance-results.json').read_text(encoding='utf-8'))
dps_samples = json.loads((ROOT / 'docs/dps-results.json').read_text(encoding='utf-8'))
dps_table = []
for unit_id, label in [('rapid', '벌컨'), ('artillery', '시즈'), ('pierce', '랜서')]:
    normal = next(row for row in dps_samples if row['unit'] == unit_id and row['armor'] == 0)
    armored = next(row for row in dps_samples if row['unit'] == unit_id and row['armor'] == 6)
    dps_table.append(f"| {label} | {normal['nominal_dps']:.2f} | {normal['measured_dps']:.2f} | {armored['measured_dps']:.2f} |")
names = {
    'random': '무작위 시작',
    'weak': '벌컨 2기 시작',
    'strong': '시즈 + 랜서 시작',
    'weak_no_growth': '벌컨 2기 / 추가 소환 없음',
    'strong_no_growth': '시즈 + 랜서 / 추가 소환 없음',
}
for key in ('random', 'weak', 'strong'):
    group = result['cohorts'][key]
    assert group['summary']['runs'] >= 100, 'Full simulation is not finished'
    assert len(group['runs']) == group['summary']['runs']
    assert len({run['seed'] for run in group['runs']}) == len(group['runs'])

lines = [
    '# 3차 실제 밸런스 결과', '',
    'Godot 4.4.1, 실제 Session/Enemy/Combat 코드, 60Hz. 시드 1–100을 각 비교군에 동일하게 적용.',
    '무작위/벌컨2/시즈+랜서 각100회와 무성장 결정론 대조군 각1회, 총302회.',
    '50G마다 즉시 소환, 동일한 고정 배치 순서, 판매/이동 없음. 초기 조합 외 후속 RNG는 동일.',
    '최대13웨이브 종료까지 측정. 14웨이브 진입자는 우측 검열(이후 생존/패배를 알 수 없음).',
    '사람 플레이 승률이 아니라 이 자동 전략의 결과다.', '',
    '| 조건 | 실행 수 | 4웨이브 이내 패배 | 10웨이브 도달 | 실제 패배 수 |',
    '|---|---:|---:|---:|---:|',
]
for key in names:
    group = result['cohorts'][key]
    stat = group['summary']
    lines.append(f"| {names[key]} | {stat['runs']} | {stat['death_by_wave4_pct']:.1f}% | {stat['reach_wave10_pct']:.1f}% | {stat['actual_game_overs']} |")
lines += ['', '## 웨이브별 평균', '',
          '웨이브 종료 직전(다음 보급 전), 또는 해당 웨이브 패배 시점에 측정. 도달한 표본만 포함하며 패배 표본의 생존 적은60이다. 따라서 표본이 줄어드는 후반 평균을 전체 플레이어 평균으로 해석하지 않는다.']
for key in ('random', 'weak', 'strong'):
    lines += ['', f'### {names[key]}', '', '| 웨이브 | 표본수 | 평균 잔여 골드 | 평균 생존 적 |', '|---|---:|---:|---:|']
    rows = result['cohorts'][key]['per_wave']
    for wave in sorted(rows, key=int):
        stat = rows[wave]
        lines.append(f"| {wave} | {stat['n']} | {stat['mean_gold']:.2f}G | {stat['mean_alive']:.2f} |")

lines += ['', '## 해석과 한계', '',
          '- 초반 패배는 살아 있는 적60기 조건에서만 발생했다. 웨이브나 난수로 강제 종료하지 않는다.',
          '- 중장갑의 타격당 방어6이 벌컨의 단발 피해9를3으로 줄인다. 시즈/랜서는 큰 단발 피해와 다중 적중으로 혼합 편성에 대응한다.',
          '- 무성장 실험은 초기 조합 이후 무작위 행동이 없어 각1회만 수행했다. 모집단 승률을 추정하는 실험이 아니다.',
          '- 즉시 소환 전략은 골드를 지속적으로 소비하므로 잔여 골드만으로 모든 플레이어의 저축량을 대표하지 않는다.',
          '- 별도의 수학적 상한: 13웨이브까지 모든 출현 적을 처치해도 처치+생존보급 총1352G, 초기 포함1452G(지출 전). 따라서 기존처럼 13웨이브에 순잔고2000G가 쌓이는 구조가 아니다.',
          '- 현재는 수동 위치 변경/판매 재추첨/기기 터치 숙련도를 모델링하지 않는다. 실제 플레이 피드백으로 추가 조정이 필요하다.',
          '', '## 단일 표적 DPS 실측', '',
          '고정 사거리, 정지 표적, 60Hz로60초 공격. 최초 즉시 공격을 포함하므로 명목 DPS와 약간 다를 수 있다. 실제 전장에서는 이동·사거리·오버킬·다중 적중에 따라 달라진다.', '',
          '| 유닛 | 명목 DPS | 무방어 실측 | 방어6 실측 |', '|---|---:|---:|---:|',
          *dps_table,
          '', '## 재현', '', '```powershell', '.\\run.ps1 -Balance', 'python tests/report_balance.py', '```', '',
          f"시뮬레이션 실행 시간: {result['seconds']:.2f}초. 원시 시드별 결과: `balance-results.json`.", '',
          '### 검증 시점 코드/데이터 SHA-256', '']
paths = ['scripts/core/game_session.gd', 'scripts/core/combat.gd', 'scripts/entities/enemy.gd',
         'scripts/data/wave_director.gd', 'data/waves.tres', 'tests/balance_simulation.gd']
paths += [str(path.relative_to(ROOT)).replace('\\', '/') for path in (ROOT / 'data/enemies').glob('*.tres')]
paths += [str(path.relative_to(ROOT)).replace('\\', '/') for path in (ROOT / 'data/units').glob('*.tres')]
for path in paths:
    lines.append(f'- `{path}`: `{hashlib.sha256((ROOT / path).read_bytes()).hexdigest()}`')
output = '\n'.join(lines) + '\n'
(ROOT / 'docs/PHASE3_RESULTS.md').write_text(output, encoding='utf-8')
print('\n'.join(lines[:17]))
print('\nRANDOM PER-WAVE (wave / n / gold / alive):')
for wave, stat in sorted(result['cohorts']['random']['per_wave'].items(), key=lambda item: int(item[0])):
    print(wave, stat['n'], round(stat['mean_gold'], 2), round(stat['mean_alive'], 2))
