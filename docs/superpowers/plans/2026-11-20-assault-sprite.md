# ASSAULT Sprite Integration Plan

**Goal:** Integrate the user's supplied atlas without changing gameplay balance.
**Architecture:** Dedicated visual scene behind the existing UnitDefinition.visual_scene seam; optional visual callbacks in Tower; combat remains authoritative.
**Tech stack:** Godot 4.4.1, GDScript, AnimatedSprite2D / AtlasTexture.
**Spec:** User Phase 4.5 request; implementation and limitations in ../../PHASE45.md.

- [x] Inspect dirty Git state and snapshot all nonignored files before editing.
- [x] Verify atlas dimensions, alpha bounds and equality with individual PNGs.
- [x] Register four six-frame animations; keep Walk/Hit reserved. Apply foot anchor and nearest filtering.
- [x] Notify animation at actual fire time; finish within each grade's attack interval. Preserve other unit aiming.
- [x] Check selection including the elevated helmet, movement, swap, sale, pause and restart in the native Windows renderer.
- [x] Run existing phase4, fire-rate and input regressions; capture real viewport images and document source defects.

Review focus: single-direction art must not spin; pause freezes frames; rapid attacks must return to idle; silhouette outside slot must be clickable; no resource balance values may change.
