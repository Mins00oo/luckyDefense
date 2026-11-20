# Phase 4.5 — ASSAULT sprite integration

## Scope and implementation

Only ASSAULT uses the new `scenes/assault_visual.tscn` and `scripts/visuals/assault_visual.gd`. The supplied atlas remains unchanged in `assets/incoming/assault/IronPerimeter_ASSAULT_visual_test/`.

- SpriteFrames registers six 128x128 frames for each row: idle, walk, attack, hit.
- Idle loops at 6 fps. Walk and Hit are reserved; movement remains instantaneous.
- CombatSystem.fire notifies the visual at actual damage time. Attack runs once for min(0.22 seconds, 85% of the grade-adjusted shot interval), then returns to Idle. The first source muzzle flash is frame 2, about 0.07 seconds after damage; damage timing is unchanged.
- Uniform scale 0.4, nearest filtering, feet baseline at slot center (source y=122). Idle alpha bounds height 104–107 px becomes 41.6–42.8 world px, including the source shadow.
- The southeast-facing artwork stays upright. No directional frames exist; tracers continue pointing at the actual target. This is a single-direction visual test, not a complete directional animation set.
- Existing slot selection border/range/grade markers remain. A small body hit rectangle also allows selecting the helmet above the slot's top edge; normal mouse and emulated touch share the input path.
- Stats, grade probabilities, other six visuals, enemy data, economy and waves are unchanged.

## Asset quality

Verified 768x512 RGBA atlas and all 24 128x128 PNGs. Every individual PNG equals its corresponding atlas tile. All alpha bounds end at y=122; no opaque pixels touch tile borders. Godot does not crop the muzzle flash.

This remains a prototype asset: idle silhouette height varies by 3 source pixels (1.2 displayed pixels), while attack varies by 9 (3.6 displayed pixels). Attack poses change rifle/body orientation and some source frames contain detached flame fragments. Dark ground shadows are baked into the sprites. Constant canvas and foot anchoring prevent whole-frame displacement, but cannot remove internal morphing or generated-source discontinuities. These need manual animation cleanup before release. No replacement artwork, trimming or frame repainting was performed.

## Verification (Windows / Godot 4.4.1)

- `tests/test_phase45_windows.gd`: 0 failures, native OpenGL / Intel Iris Xe. Actual viewport screenshots: `phase45-idle.png`, `phase45-attack.png`.
- Tested actual mouse input on helmet for select/deselect, movement to empty slot and swapping with another soldier.
- Tested preparation to wave 1, damage/animation synchronization, attack after combat relocation, all five grade intervals, idle recovery, pause/resume, confirmed sale/refund, duplicate-sale rejection, resummon and restart.
- Existing `test_phase4.gd`: 0 failures. `test_fire_rate.gd`: 0 failures. `test_input.gd`: PASS.
- These are automated runtime tests, not a claim of prolonged manual play or iOS device validation. No new balance simulation was needed for this visual-only change.

## Play and review

Normal: open project.godot and F5, or `./run.ps1`.

Guaranteed ASSAULT preview: `./run.ps1 -AssaultPreview`. It first runs the visual checks, then resets to a fresh preparation phase with two normal-cost ASSAULT soldiers. Subsequent summons use the original random catalog. Click a soldier (including its helmet), click an empty slot to move, click another soldier to swap; click again, right-click or ESC to deselect. Select Sell then confirm to receive 25G. Pause freezes animation. Restart restores normal initial state.

Noninteractive verification: `.tools/Godot_v4.4.1-stable_win64_console.exe --path . --script tests/test_phase45_windows.gd`.

## Recovery

Pre-edit snapshot: `.tools/backups/pre-phase45-20261120-174321/workspace.zip`, with `git-status.txt` and `git-head.txt`. It includes tracked and untracked nonignored project files, preserving earlier uncommitted work. Git was already dirty; no reset, checkout, stash or commit was performed.

Restore only affected existing files from that archive to revert this stage: `data/units/assault.tres`, `scripts/entities/tower.gd`, `scripts/core/combat.gd`, `scripts/core/board.gd`, `run.ps1`. New files in this stage are the dedicated visual scene/script, runtime test, this report, plan and screenshots. Do not reset the entire Git working tree: that would discard previous phases.
