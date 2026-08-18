# Ponto Cego — Project Context

2D top-down stealth game, Godot 4.7, GDScript 2.0 (typed). Manuela sneaks
through 3 tower stages (corridor / kitchen / garden), avoiding guard vision
cones, collecting power-ups, completing objectives, reaching the exit door.

Design source: `SGDD.md` (Portuguese). This file governs implementation and
overrides the SGDD on anything they disagree on. **Keep this file in sync
with the codebase as tasks land — verify via MCP before trusting it.**

## Before starting any task

Inspect the real project via MCP (structure, scenes, node trees, relevant
scripts) before proposing a plan. If reality differs from this doc, follow
reality and flag the mismatch — don't silently reconcile.

## Structure

Flat — no subfolders under `scenes/`/`scripts/`.

```
res://
  scenes/
    main_menu.tscn, hud.tscn, pause_menu.tscn
    instructions_screen.tscn, instructions_modal.tscn
                                 (both instance instructions_content.tscn)
    instructions_content.tscn   (shared item-explanations content, no script)
    base_screen.tscn            (shared full-rect background + title;
                                 main_menu.tscn, instructions_screen.tscn,
                                 and base_end_screen.tscn all instance it)
    confirm_buttons.tscn        (shared Sim/Não row; base_end_screen.tscn
                                 and pause_menu.tscn both instance it)
    base_end_screen.tscn        (shared template)
    defeat_screen.tscn          (Continuar / quit-with-confirm)
    credits_screen.tscn         (shown only after stage 3)
    base_map.tscn, base_wall.tscn, base_item.tscn
    key.tscn, invisibility_potion.tscn, wind_bag.tscn   (instance base_item.tscn)
    hud_item_slot.tscn          (shared bottom-left inventory slot; hud.tscn's
                                 PotionSlot/WindBagSlot/KeySlot all instance it)
    base_illumination_asset.tscn (shared candle/torch template)
    candle1.tscn, candle2.tscn, torch1.tscn, torch2.tscn (instance it)
    candle.tscn                 (old ColorRect placeholder, unused — dead file)
    exit_door.tscn
    knight.tscn                 (guard; has PatrolRoute > Marker2D waypoints)
    player.tscn
    1_tower.tscn                 (stage 1/corridor. CLAUDE.md previously claimed
                                 this was renamed to 1_corridor.tscn — that
                                 rename never happened; the file is still
                                 1_tower.tscn. Don't trust the "1_corridor"
                                 name elsewhere until this is actually done.)
    2_kitchen.tscn                (stage 2, actively WIP — see "Map & walls"
                                 below, which no longer matches this scene's
                                 real layout. LevelManager's stage-2 slot
                                 now points here)
    3-garden.tscn                 (stage 3. base_map.tscn instance with
                                 overridden floor/border textures from
                                 sprites/assets/3-yard/. Has knights, player,
                                 items, ExitDoor+KeyDoorObjective, HUD,
                                 PauseMenu, and hand-placed interior hedge
                                 walls — see "Map & walls" below for the
                                 YSort/wall-sprite structure. LevelManager's
                                 stage-3 slot now points here (see "Map &
                                 walls"). Note the hyphenated filename,
                                 unlike 1_tower.tscn/2_kitchen.tscn's
                                 underscore convention. Still under active
                                 hand-editing (hedge/wall placement) —
                                 verify current layout via MCP before
                                 trusting exact positions/sizes here.)
    base_cauldron.tscn, cauldron1.tscn  (cauldron illumination asset, instances
                                 base_illumination_asset.tscn like candle/torch;
                                 undocumented until now — flag if this split
                                 base/leaf pattern surprises you elsewhere)
  scripts/
    event_bus.gd, game_manager.gd, level_manager.gd,
    scene_transition.gd, suspicion_manager.gd     (autoloads)
    player.gd, knight.gd
    base_item.gd, exit_door.gd, candle.gd, base_illumination_asset.gd, wall.gd
    objective.gd, key_door_objective.gd, level_objectives.gd
    base_screen.gd               (background/title shell; main_menu.gd and
                                 instructions_screen.gd extend it directly,
                                 base_end_screen.gd extends it too)
    confirm_buttons.gd            (Sim/Não row; confirmed/cancelled signals)
    hud_item_slot.gd
    hud.gd, main_menu.gd, pause_menu.gd, instructions_screen.gd,
    instructions_modal.gd, base_end_screen.gd, defeat_screen.gd, credits_screen.gd
  sprites/  assets/ (door/, candle1-2/, torch1-2/), itens/ (key/potion/wind_bag),
            knight/, player/, ui/
            assets/1_corridor/, assets/2_kitchen/ — per-stage wall/floor sprite
            sets (sidewall/interior-wall/exterior-wall/side-exterior-wall/floor,
            same filenames in each folder). Replaced the old shared assets/wall/
            folder so each stage can point base_wall.tscn/base_map.tscn at its
            own look via the body_texture export (see "Map & walls").
  sounds/   6 licensed SFX clips + 2 full-length music tracks — see
            "Audio hooks" below for what's wired where.
  fonts/    Darinia.ttf (the game's only font, applied project-wide via
            theme.tres — see "Fonts & backgrounds"), Darinia.png (a
            glyph-specimen texture, not used by the game), license.txt,
            ornaments/ (ornament1-3.png, decorative flourishes — not
            currently used anywhere, flag before wiring or deleting).
  backgrounds/  HR_Dark Gothic Castle.png (main menu), HR_Deep Forest.png
            (victory/credits screen) — see "Fonts & backgrounds".
theme.tres  Project-wide Theme resource (default_font = fonts/Darinia.ttf),
            registered as gui/theme/custom in project.godot. Root-level,
            not under scenes/ or a dedicated theme/ folder.
```

No level-select screen and no `.tres` stage config files — objectives are
authored as an exported `Array[Objective]` directly on each stage's
`LevelObjectives` node.

## Autoloads (load order: EventBus, SuspicionManager, GameManager,
LevelManager, SceneTransition)

- **GameManager** — `enum GameState { PLAYING, STAGE_COMPLETE, GAME_COMPLETE, DEFEAT }`.
  `restart_level()`, `complete_stage()` (advances, or `trigger_game_complete()`
  on the last stage), `trigger_defeat(guard)`, `quit_to_main_menu()`.
- **LevelManager** — linear only: `current_stage_index`, `total_stage_count`,
  `is_last_stage()`, `advance_to_next_stage()`. Has unused dead
  `unlock_level()`/`is_level_unlocked()` left from an old design — flag
  before removing, don't delete silently.
- **SuspicionManager** — owns the actual detection "grace period": suspicion
  rises toward 1.0 over `time_to_max` (2.0s) while any guard sees the
  player, drains over `time_to_drain` (4.0s) once none do. Hitting 1.0
  triggers capture. `report_visibility(guard, sees_player)`, `suspicion`,
  `suspicion_changed(value)`, `reset()`.
- **SceneTransition** — `goto_scene(path)`, fades (0.25s default). Always use
  this instead of `change_scene_to_file()` directly.
- **EventBus** — signals only, no state: `player_detected(guard)`,
  `player_lost(guard)` (both fire immediately, no debounce — see
  SuspicionManager for the real grace logic), `objective_completed(id)`,
  `all_objectives_completed()` (emitted by LevelObjectives once every
  objective in its list is done; ExitDoor listens for this instead of
  reaching into LevelObjectives on every touch), `level_completed()`
  (covers both stage-advance and full-game-complete), `player_captured(guard)`,
  `item_picked_up/consumed`, `power_up_activated/expired`,
  `candles_extinguished()`. `level_exited()` is declared but unused — don't
  rely on it.

## State machines

- **Knight** (`knight.gd`): `enum State { IDLE, PATROL, ALERT, LOOK_AROUND }`.
  IDLE if <2 `PatrolRoute` waypoints, else PATROL. A single-waypoint Knight
  (IDLE) faces that waypoint on `_ready()` — `facing_direction` is set to
  the direction toward it instead of staying at the `Vector2.RIGHT` default
  — so its periodic idle look-around (see `LOOK_AROUND` below) sweeps
  centered on that marker instead of always facing right. A
  zero-waypoint Knight still defaults to facing `Vector2.RIGHT`, unchanged.
  `ALERT` is still a stub
  (`_process_alert()` just zeroes velocity) and currently **unreachable** —
  nothing in the codebase transitions a Knight into `ALERT` yet. `LOOK_AROUND`
  triggers via a shared `_start_look_around()`, called on waypoint arrival
  (PATROL) or a periodic timer (`look_around_idle_interval`, IDLE). It sweeps
  facing_direction ± `look_around_sweep_angle_degrees / 2` (export, default
  45°, hard-capped at 80°) from the angle it was facing when the sweep
  started — never turns to face behind itself. If detection fires mid-sweep,
  `_cancel_look_around()` reverts state to whatever it was *before* the
  sweep (IDLE or PATROL), not ALERT — detection itself is handled separately
  by `_update_detection()`/`SuspicionManager`. The vision cone keeps
  updating every physics frame regardless of state, so it visibly sweeps
  during LOOK_AROUND too.
- **Player** (`player.gd`): `enum State { IDLE, WALKING }` only — no
  Drinking state. Potion/wind-bag use are instant one-shot actions.
  Invisibility is a plain bool + Timer, independent of State.

## Illumination

`base_illumination_asset.gd` builds a purely visual glow, not real
occlusion-aware lighting (no `Light2D`/`CanvasModulate` anywhere in the
project) — a flat `Polygon2D` under `$Light`, same runtime-vertex technique
as Knight's vision cone, additive-blended (`CanvasItemMaterial.blend_mode
= 1`) so overlapping glows brighten. Rebuilt in `_build_light_polygon()`
whenever `light_radius`/`light_angle_degrees`/`flip_h` change.
`light_angle_degrees` (export, default 360) draws a full circle at
`>= 360`, otherwise a wedge centered on the facing direction (`Vector2.
LEFT`/`RIGHT` from `flip_h`, matching the sprite's own flip convention).
`extinguish()` hides `$Light` along with playing the `blown` animation.
Every leaf fixture's `SpriteFrames` must define a `lit` animation (the
base's `AnimatedSprite2D.autoplay` is `"lit"`) and a non-looping `blown`
animation, or `extinguish()`'s `sprite.play(&"blown")` fails to find it.
`cauldron1.tscn` is in the `"illumination"` group like every other
fixture (inherited from the base scene's root, not re-declared per leaf)
so `player.gd`'s `_use_wind_bag()` extinguishes it along with every
candle/torch — its `blown` frame is the single static
`sprites/assets/cauldron/cauldron-off.png` (48x44, no atlas slicing,
unlike its 12-frame `lit` animation which *is* sliced from the larger
`cauldron.png` sheet via `AtlasTexture` sub-resources).
Per-fixture overrides live in the leaf scenes, not the base: `candle1`/
`candle2` stay at the 360° default; `torch2` (freestanding) also stays
360°; `torch1` (wall-mounted — the 4 pillar instances in `1_tower.tscn`)
is the only one set to `light_angle_degrees = 180.0`. Radius/color differ
per fixture to read as distinct light sources — check the leaf `.tscn`
files directly for current values rather than trusting numbers here.

## Map & walls

**Verified via MCP 2026-08-03 — the previous version of this section
described an irregular-room, hidden-border kitchen design (2x2 rooms, 20
hand-placed `base_wall.tscn` segments, `base_map.tscn`'s border hidden via
`visible = false`/`collision_layer = 0`) that does not exist in the
committed `2_kitchen.tscn`. That may still be the eventual plan, but
nothing in the repo builds it today — treat the paragraph below as current
reality, not the old one.**

`base_map.tscn` defines a *fixed, rectangular* boundary of its own:
`BaseMap` (Node2D) + `Background` (`TextureRect`, floor tileset) +
`LeftBorderWall`/`RightBorderWall`/`TopBorderWall`/`BottomBorderWall`
(plain `TextureRect`s, not `base_wall.tscn` instances) + `MapBorder`
(`StaticBody2D` with 4 `CollisionShape2D`s, one per side). Both
`1_tower.tscn` (stage 1; **still named `1_tower.tscn`** — a doc-only rename
to `1_corridor.tscn` was claimed before but never done) and `2_kitchen.tscn`
use this border **as-is, fully visible with real collision** — neither
stage hides it. `1_tower.tscn` only adds two freestanding `base_wall.tscn`
instances (`Wall1`/`Wall2`, under `YSort`) as interior pillars.
`2_kitchen.tscn` currently only adds four freestanding wall instances
(`Wall1`-`Wall4`, parented at scene root, **not** under `YSort`) plus one
`cauldron1.tscn` (`BaseIlluminationAsset`) instance near the room's center
— there is no irregular room layout, no hidden border, and nowhere near 20
wall segments; this stage is early WIP (see its git history) and the
"20 segments / hidden border / 2x2 rooms" design from earlier revisions of
this doc has not been built.

`2_kitchen.tscn`'s four wall instances are `base_wall.tscn`, same as
`1_tower.tscn`'s `Wall1`/`Wall2` — there used to be a second near-duplicate
leaf scene, `base_wall2.tscn`, with `sprites/assets/2_kitchen` textures
hardcoded into its own `Body`/`Boot` `TextureRect`s (created because
`wall.gd` had no per-instance texture override at the time); it's been
deleted. `wall.gd` now has `body_texture`/`boot_texture` exports (`Texture2D`,
default unset) applied in `_apply_textures()` — set means override
`$Body`/`$Boot`'s texture, unset means keep whatever `base_wall.tscn`
authors on those nodes. `2_kitchen.tscn`'s `Wall1`-`Wall4` set both to the
kitchen's `sidewall.png`/`side-exterior-wall.png`; `1_tower.tscn`'s
`Wall1`/`Wall2` leave both unset and keep `base_wall.tscn`'s own default
(`sprites/assets/wall/sidewall.png`/`side-exterior-wall.png`).

`wall.gd`'s `size` (thickness x length) plus node position (the wall's
base point) support both vertical and horizontal runs, but **not via
rotation and not via "whichever dimension of `size` is larger"**. Swapping
which axis is longer only renders correctly when `connects_to_wall = true`;
leaving it `false` computes a boot height from the boot texture regardless
of orientation, which goes negative for a short/wide (horizontal) box. So
in practice: vertical runs use `size = (thickness, length)`, horizontal
runs use `size = (length, thickness)`, and every hand-placed
boundary/divider segment that butts against another at each end sets
`connects_to_wall = true` (no boot wanted there regardless of the bug).

`LevelManager`'s stage array (`level_manager.gd`) now points stage 2 at
`res://scenes/2_kitchen.tscn` and stage 3 at `res://scenes/3-garden.tscn`
— the full menu → stage 1 → stage 2 → stage 3 → credits flow is wired via
`GameManager.complete_stage()`/`trigger_game_complete()`.

`3-garden.tscn`'s `LeftBorderWall`/`RightBorderWall` (inherited from
`base_map.tscn`) are hidden (`visible = false`, texture override removed)
rather than deleted, same "override to kill the default, hand-place your
own" pattern as the irregular-stage approach described above — the
underlying border rect only ever existed to be replaced by hand-placed
hedge sprites, so it carries no texture now that those are in place.
In their place, `LeftHedge1`-`LeftHedge14`/`RightHedge1`-`RightHedge5`
(numbering has gaps from hand-editing — not a contiguous 1-14 run) are
manually stacked `TextureRect` copies of `sprites/assets/3-yard/wall-bg.png`
(a 64x192 hedge-column sprite with an organic, non-seamless bumpy
silhouette). Border-edge copies overlap vertically so the bumpy edges
blend instead of leaving a seam; sibling order among them determines which
copy paints over the seam, so a duplicate or out-of-order node here
reads as a visible gap — check live via MCP rather than trusting exact
node names/positions, this set has been hand-tuned repeatedly.
`TopBorderWall`/`BottomBorderWall` still use `exterior-wall.png`.

The interior of the garden has hand-placed maze walls: `InnerWall5`-
`InnerWall7` (horizontal segments, textured with `exterior-wall.png`,
`stretch_mode = TILE`, sized to match `MapBorder`'s `CollisionShape2D5`-
`CollisionShape2D7`) plus more `LeftHedge*` copies used as vertical
interior segments (`wall-bg.png`), and `Boot1`-`Boot4` (`sprites/assets/
3-yard/boot.png`) as ground-level decorative bases at the foot of the
vertical hedge columns — collision for all of these lives on `MapBorder`'s
`CollisionShape2Dx` children, the sprites carry no collision of their own.

`3-garden.tscn` now has a `YSort` node (root child, `y_sort_enabled =
true`, sibling index placed *before* the hedge/wall/boot sprites but
*after* Background/border walls) holding `Knight`/`Knight2`/`Knight3`/
`Knight4`, `Player`, `ExitDoor`, `Key`, `WindBag`, `InvisibilityPotion`,
and `LevelObjectives` — mirroring `2_kitchen.tscn`'s `YSort` grouping.
As in `2_kitchen.tscn`, the wall/hedge sprites themselves are **not**
inside `YSort` — they're root siblings positioned after it in sibling
order, so (like `2_kitchen.tscn`'s `Wall1`-`Wall4`) they draw on top of
characters unconditionally, not true Y-sorted depth. `Boot1`-`Boot4` are
the one exception: since they're walkable-over ground decals with no
collision of their own (unlike the solid hedge/wall sprites), they're
positioned *before* `YSort` instead, so they draw underneath the player
like floor texture rather than occluding it. `3-garden.tscn` has a
`KeyDoorObjective`-based `LevelObjectives` (same pattern as
`2_kitchen.tscn`'s, `door_path = "../ExitDoor"`) and `HUD`/`PauseMenu`
instances at scene root, same as the other two stages.

## Objectives

`LevelObjectives` (`level_objectives.gd`) holds an exported
`Array[Objective]` and calls `objective.setup(self, on_complete)` on each
one in `_ready()`. `Objective.setup()` is a virtual no-op; `KeyDoorObjective`
overrides it to lock its target `ExitDoor` and connect its own
`EventBus.item_picked_up` listener, calling `on_complete` when its key is
picked up. Adding a new objective type means overriding `setup()` on it,
not branching inside `LevelObjectives`. `LevelObjectives` emits
`EventBus.all_objectives_completed` once `completed_count >= total()`
(including immediately in `_ready()` for a level with zero objectives).

## HUD

- Suspicion bar (`$Root/SuspicionBar` in `hud.tscn`) has no text label
  anymore (the old `TopLeft`/`SuspicionLabel` nodes were removed) and is
  now anchored top-center instead of top-left. It starts at
  `modulate.a = 0` and `hud.gd` drives visibility by tweening alpha rather
  than toggling `.visible`: rising suspicion tweens alpha to 1.0 over
  `SUSPICION_FADE_DURATION` (0.3s); draining suspicion tracks alpha
  directly to the value once below `SUSPICION_FADE_THRESHOLD` (0.2) since
  `SuspicionManager` already emits a smoothly-interpolated value while
  draining, so a second tween would fight it.
- The three bottom-left inventory slots (`PotionSlot`/`WindBagSlot`/
  `KeySlot` under `Root/BottomLeft`) are all instances of
  `hud_item_slot.tscn` (icon texture + optional hint-key label, set
  per-instance via exports); `hud.gd` still reaches into each instance's
  `Icon`/`ActiveFill`/`TimerLabel` by path for runtime state (inventory,
  potion timer). Inventory icon visibility is driven by a
  `StringName -> TextureRect` table (`_item_slot_icons`) rather than
  per-item branches, so a new inventory item only needs a new table entry.
- The potion countdown/fill (`ActiveFill`/`TimerLabel` on `PotionSlot`) is
  computed locally in `hud.gd` from the `duration` carried by
  `EventBus.power_up_activated` — HUD does not hold a reference to
  `Player` or poll it every frame.

## Pause menu & instructions

- `instructions_content.tscn` is the single source of the item explanations
  (Key / Invisibility Potion / Wind Bag) — a self-contained scrollable
  Control with no assumptions about its container's size. Both
  `instructions_screen.tscn` (full-screen, reached from `main_menu.tscn`'s
  "Instruções" button) and `instructions_modal.tscn` (small translucent
  centered panel, opened from the pause menu) instance it rather than
  duplicating content.
- `pause_menu.tscn` is triggered by the `pause` InputMap action (Escape),
  added alongside `hud.tscn` in stage scenes. Wired into all three stages —
  `1_tower.tscn`, `2_kitchen.tscn`, and `3-garden.tscn` (all instanced at
  the scene root, order doesn't matter since both are `CanvasLayer` roots).
- Root `PauseMenu` node has `process_mode = PROCESS_MODE_ALWAYS`; everything
  else (Knight, Player, SuspicionManager timers) is left at the default
  `PROCESS_MODE_INHERIT` so `get_tree().paused = true` freezes them without
  any per-node opt-out. "Continue" is `resume_game()` — deliberately not
  `GameManager.restart_level()`, which is a different action (DefeatScreen's
  "Continuar" restarts the stage; this just unpauses).
- Opening instructions from the pause menu does not unpause — it swaps the
  4-button panel for `instructions_modal.tscn` in place, still paused.
- Menu Principal and Sair do Jogo both swap the 4-button panel for a
  `ConfirmPanel` (its `ConfirmButtons` child is a `confirm_buttons.tscn`
  instance — the same Sim/Não component `BaseEndScreen` uses for its
  main-menu-exit confirmation), same lost-progress warning text as
  `BaseEndScreen`'s own confirm, since both actions end the run with
  nothing saved. Only "Sim" unpauses (`get_tree().paused = false`)
  before calling `GameManager.quit_to_main_menu()` for the main-menu case —
  so the main menu itself doesn't load paused — or `get_tree().quit()` for
  the quit-game case.

## Naming

- `guarda` → **`Knight`** in code (not `Guard`) — every guard script/scene/
  node uses this name. Prose/comments can still say "guard".
- No standalone `LockedDoor` — locking lives on `ExitDoor`
  (`set_locked()`/`unlock()`), driven by `KeyDoorObjective`.
- Files/folders: `snake_case` (exception: `sprites/itens/`, left as-is).
- Nodes: `PascalCase`. Classes (`class_name`): `PascalCase`, only where
  something needs to reference the type directly (`LevelObjectives`,
  `Objective`, `KeyDoorObjective`, `ExitDoor`, `BaseScreen`,
  `BaseEndScreen`, `ConfirmButtons`). `hud_item_slot.gd` deliberately has
  no `class_name` — nothing references it by type, only by scene path.
- Signals: `snake_case`, past tense (`player_detected`, `objective_completed`).
- Constants: `SCREAMING_SNAKE_CASE`.
- Enum values: `SCREAMING_SNAKE_CASE` (`State.LOOK_AROUND`, `GameState.STAGE_COMPLETE`).
- Typed GDScript everywhere feasible.

## Audio hooks

Pattern: `@onready` an `AudioStreamPlayer(2D)`, `print()` a placeholder tag
matching the SGDD's bracket notation (e.g. `[som: alerta!]`), only call
`.play()` if `.stream != null`. Follow this exact pattern for new cues.

`sounds/` holds a small licensed SFX pack (one `.wav` + its `.import` per
subfolder, subfolder name is the sound's category) — trimmed down from a
much larger pack to just the 6 clips actually wired in; unused
folders/files were deleted rather than left around unreferenced. Wired so
far, all via `stream = ExtResource(...)` set directly in the `.tscn`
(no code changes needed):
- `base_item.tscn`'s `PickupSound` → `sounds/Coin/Coin1.wav` (generic
  pickup jingle, used by Key/Potion/WindBag alike since they all instance
  `base_item.tscn`).
- `player.tscn`'s `DrinkSound` → `sounds/Drinking/DrinkingSingleGulp1.wav`.
- `player.tscn`'s `WindSound` → `sounds/WingFlap/WingFlap1.wav` — the pack
  has no wind/whoosh/blow category, this was the closest air-motion sound
  available; revisit if a better-fitting asset shows up.
- `knight.tscn`'s `AlertSound` → `sounds/Alarm(Loopable)/Alarm2(Fast).wav`
  (the fast one-shot variant, not the loopable one — this fires once per
  detection, it doesn't loop).
- `exit_door.tscn` — previously had no `AudioStreamPlayer` at all, only
  the `open_label` print. Added an `OpenSound` (`AudioStreamPlayer2D`)
  node wired to `sounds/Door/DoorKnobOpening1.wav`, and
  `exit_door.gd`'s `_play_open_placeholder()` now checks
  `open_sound.stream != null` and plays it, matching every other hook.
- `click_sfx` (exported `AudioStream`, not a raw node — see each script's
  own `@export var click_sfx: AudioStream`) on `main_menu.tscn`,
  `instructions_modal.tscn`, `instructions_screen.tscn`, and
  `pause_menu.tscn` → all four set to `sounds/Click-Button-Switch/
  Click1.wav` as a scene-level export override, per the "drop a real
  AudioStream into click_sfx ... in the editor, code doesn't need to
  change" comment already in `main_menu.gd`.

Two full-length music tracks were later added directly to `sounds/`
(not inside a category subfolder, unlike the SFX above — `sounds/menu.wav`
and `sounds/gameplay.wav`, ~87s and ~70s respectively) and are now wired:
- `main_menu.gd`'s `menu_music` export → `sounds/menu.wav`, set as a
  scene-level override on `main_menu.tscn` same as `click_sfx`.
  `MusicPlayer`'s `volume_db` is set to `-8.0` on the node directly (the
  script never touches `volume_db`, only `.stream`, so this sticks).
- Every stage root (`1_tower.tscn`, `2_kitchen.tscn`, `3-garden.tscn`) got
  a new root-level `GameplayMusic` (`AudioStreamPlayer`, non-positional —
  matches `MusicPlayer`'s type, not the `*2D` SFX nodes) with `autoplay
  = true` and `stream` → `sounds/gameplay.wav`. No script involved (these
  stage roots have no root script to begin with), so it just starts
  playing on scene enter and gets freed on scene transition like anything
  else in the tree. One track shared across all three stages — SGDD's
  "por área" per-area variation was never built, this is a single loop.
- Both `.wav.import` files have `edit/loop_mode` set to `1` (Forward,
  full-track loop) — the default from Godot's WAV importer is `0`
  (disabled) and would otherwise play once and go silent.
- Loudness was deliberately capped relative to the SFX above, checked via
  `ffmpeg -af volumedetect`: the SFX peak between -0.8 and -3.3 dBFS
  (mean -15.3 to -26.1 dB). Both raw tracks import near 0 dBFS peak
  (menu -0.1 dB/-13.9 dB mean, gameplay -0.1 dB/-16.5 dB mean), so
  playing them unattenuated would sit at or above every SFX cue.
  `-8.0 dB` on menu music lands its peak around -8.1 dB (still under the
  quietest SFX peak) while staying audible as the only sound on that
  screen; `-12.0 dB` on gameplay music (deliberately more attenuated,
  since it now has to sit *under* Coin/Drinking/WingFlap/Alarm/Door
  during play) lands its mean around -28.5 dB — below every gameplay
  SFX's mean, including Drinking's -26.1 dB (the quietest) — so it never
  outweighs a foreground cue. If new SFX get added later with a mean
  quieter than -26 dB, re-check `gameplay.wav`'s `volume_db` against it.

Still unwired: "música de vitória/derrota" (credits/defeat screens) — no
placeholder existed for them in code to begin with (unlike the
`[som: ...]` cues above, `credits_screen.gd`/`defeat_screen.gd` never had
an `AudioStreamPlayer` or export hook), and no asset for them has been
dropped into `sounds/` yet. `game_manager.gd`'s capture-related
`print("[game over] captured by ", guard)` is a plain debug log, not one
of these SGDD-bracket placeholders — GameManager is a bare-script
autoload with no scene/node tree to hang an `AudioStreamPlayer` from.

## Fonts & backgrounds

`theme.tres` (repo root) is a `Theme` resource with `default_font` set to
`fonts/Darinia.ttf`, registered project-wide via `project.godot`'s
`[gui]` section (`theme/custom="res://theme.tres"`). This is the *only*
mechanism styling text — no scene sets a per-node font override (checked:
none use `theme_override_fonts/font`), so every `Label`/`Button`/etc. in
the game picks up Darinia through the default-theme cascade automatically.
New Controls don't need any per-node wiring to pick up the font; only add
a node-level font override if something needs to deliberately deviate.
`fonts/Darinia.png` is a glyph-specimen image bundled alongside the
`.ttf`, not a bitmap font resource — unused by the game.
`fonts/ornaments/` (ornament1-3.png) is unused; flag before wiring or
deleting since it's unclear if a future screen wants them.

Two background images from `backgrounds/` are wired, both as a same-file
`BackgroundImage` (`TextureRect`) added directly in the leaf scene rather
than in `base_screen.tscn`, matching that file's "callers add their
own... content as extra children" convention. Layering is done with
explicit `z_index` on both nodes rather than sibling/tree order (simpler
than juggling node indices across instance levels): the inherited
`Background` `ColorRect` (opaque `background_color`, alpha 1.0) gets a
node override setting `z_index = -2`, and `BackgroundImage` sits at
`z_index = -1` — one step above the opaque color layer, one step below
`Title`/buttons which stay at the default `z_index = 0`. Getting this
backwards (image at `-1` with `Background` left at its default `0`) was
tried first and silently failed: the texture loaded with no errors, it
was just fully painted over by the opaque `ColorRect` sitting at the same
effective layer — a rendering/z-order bug, not a missing-resource one, so
it won't show up in the debug/error log. If a background image ever
looks "not loaded" again on a `BaseScreen`-derived screen, check this
z_index relationship before suspecting the resource path/UID.
- `main_menu.tscn` → `backgrounds/HR_Dark Gothic Castle.png`.
- `credits_screen.tscn` (the victory screen — shown once, after the last
  stage's exit) → `backgrounds/HR_Deep Forest.png`. Added as an override
  two instancing levels down (`CreditsScreen` → `base_end_screen.tscn` →
  `base_screen.tscn`); Godot resolves the `[node name="..." parent="."
  index="N"]` override pattern by node path regardless of how many
  instance levels deep the node's actual declaration lives, same as
  `base_end_screen.tscn`'s own pre-existing `Title` override.
- `defeat_screen.tscn` and `instructions_screen.tscn` deliberately did
  **not** get a background image or the readability treatment below —
  nothing was supplied/asked for those, they keep `base_screen`'s flat
  `background_color`.

Both `TextureRect`s use `expand_mode = 1` (`EXPAND_IGNORE_SIZE`) +
`stretch_mode = 6` (`STRETCH_KEEP_ASPECT_COVERED`) on full-rect anchors —
crops to cover rather than letterboxing, so the flat-color `Background`
underneath never shows through at the edges. Both also set
`mouse_filter = 2` (`MOUSE_FILTER_IGNORE`) — without it, a full-rect
`TextureRect` blocks Godot's GUI input hit-testing (which follows sibling
order, not `z_index`) for anything drawn under it. This bit
`credits_screen.tscn` specifically: `BackgroundImage` there has no
explicit index, so it gets appended *after* the already-existing
inherited `Buttons` node (unlike `main_menu.tscn`, where `Buttons` is
added fresh later in that same file and so ends up after
`BackgroundImage`) — meaning it silently ate every click on that screen
while still rendering correctly underneath, with no error logged either
way. `main_menu.tscn`'s copy got the same `mouse_filter` fix even though
its sibling order happened to work by accident, so it isn't relying on
that ordering staying lucky.

Readability over the busy images, both screens:
- `Title` gets a black `font_outline_color` + `outline_size = 8` node
  override (on top of `base_screen.gd`'s existing runtime
  `TITLE_FONT_SIZE` override — different properties, no conflict).
- Buttons that sit over the image (`main_menu.tscn`'s Play/Instructions/
  Quit; `credits_screen.tscn`'s `PrimaryButton` — its `MainMenuButton` is
  hidden via `show_main_menu_button = false` so wasn't styled) get a
  translucent black `StyleBoxFlat` panel (`theme_override_styles/normal`
  at alpha 0.55, `/hover` 0.72, `/pressed` 0.88, all with 8px rounded
  corners) rather than relying on the engine's default flat button style.
  Each `.tscn` defines its own copy of these `StyleBoxFlat` sub-resources
  (shared across that file's own buttons, not shared cross-file) rather
  than putting them in `theme.tres` — deliberate, since a project-wide
  default Button style would also hit pause menu / confirm dialogs /
  instructions screen buttons that were never asked for and don't sit
  over a busy background.

`base_end_screen.gd`/`.tscn` grew a third `DefaultButtons` entry,
`QuitGameButton` (`get_tree().quit()`, no confirmation), gated by a new
`show_quit_game_button` export (default `false`, mirroring
`show_main_menu_button`'s pattern). `defeat_screen.tscn` leaves it off
(unchanged, still just Continuar/Menu principal); `credits_screen.tscn`
sets `show_quit_game_button = true` — same "no run left to lose, so no
confirmation needed" reasoning as its own `show_main_menu_button = false`
+ confirmation-less primary button. If DefeatScreen ever wants this too,
it's a one-line export flip, no script changes needed.

## Known drift risks

Sizes/positions in `.tscn` files here get hand-edited in the Godot editor
often and have drifted before — verify against the live scene via MCP
rather than trusting numbers below as current:

- `exit_door.tscn`'s `NextStageVoid` `ColorRect` (the black void seen
  through the open door gap) and `1_tower.tscn`'s `ExitDoor.position`
  have both been repositioned multiple times as door art changed. Check
  current values before assuming either is stable.
- `1_tower.tscn`'s perimeter is still `base_map.tscn`'s fixed
  4-`TextureRect`-strip + `MapBorder` rectangle (1280x720, unmodified) —
  see "Map & walls" above for what's actually true here; earlier versions
  of this doc claimed it had been migrated to hand-placed `base_wall.tscn`
  instances, which was never done.
- `1_tower.tscn`'s torch layout currently has only 2 freestanding
  `torch2` instances (`TorchTopLeft`/`TorchTopRight`) plus 4 wall-mounted
  `torch1` instances on the two interior pillars — the bottom-border
  torches that used to exist were removed. Don't assume a symmetric
  top+bottom layout.
- `2_kitchen.tscn`'s actual current wall count is 4 (`Wall1`-`Wall4`,
  `base_wall2.tscn` instances), not the 20-segment irregular-room design
  described in earlier revisions of this doc — see "Map & walls" above.
  Item/guard/door coordinates here are easy to hand-drift out of sync in
  the editor like everything else in this list — verify positions via MCP
  rather than trusting the numbers here if this scene has been opened in
  the editor since.
- `2_kitchen.tscn`'s four `Knight` nodes have varying `PatrolRoute` sizes
  (0, 1, 2, or 4 markers) exercising every `Knight` state-selection branch
  — `Knight3`/`Knight2` are the single-marker cases the look-toward-marker
  fix (see "State machines" above) targets.

## Git & verification

- One feature per commit; commit after each task is MCP-verified, before
  starting the next.
- Don't touch more than 2-3 `.tscn` files in one session without committing.
- Always run the scene via MCP and check for errors before calling a task
  done. Report what was actually verified vs. left as placeholder.
