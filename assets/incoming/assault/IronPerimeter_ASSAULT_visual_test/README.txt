IRON PERIMETER - ASSAULT VISUAL TEST ASSET PACK
================================================
This pack contains a first-pass AI-generated sprite sheet for visual integration only.

Assets
- ASSAULT_atlas_6x4_128.png: 6 columns x 4 rows; each tile 128 x 128 px
- frames_128/: 24 transparent 128 x 128 PNG tiles
- source_assault_sheet.png: raw 1254 x 1254 reference sheet
- manifest.json: animation names and frame paths

Frame rows (top to bottom)
row 0 idle (6 frames)
row 1 walk (6 frames)
row 2 attack (6 frames)
row 3 hit reaction (6 frames)

IMPORTANT:
- Source sheet is AI-generated, not manually animated. Frames may jitter and flash; inspect in-game and refine before release.
- Some generated frames include glow, muzzle fire, or ground shadow as part of the sprite.
- Keep existing combat logic and balance unchanged. Only replace ASSAULT's visible art and animations.
- Use nearest texture filter in Godot for pixelated graphics; adjust actual world display scale to existing slots.
- Do not stretch sprites non-uniformly.
- This is not StarCraft artwork and should not be marketed as an official Blizzard asset.
