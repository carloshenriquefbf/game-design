# Ponto Cego — Project Context

## Overview

**Ponto Cego** is a 2D top-down stealth game built in Godot 4.7 (GDScript
2.0, typed). The player controls Manuela, who must sneak through 3 areas of
a tower (corridor / kitchen / garden), avoiding guard vision cones,
collecting power-ups, completing per-stage objectives, and reaching each
exit door.

Full design reference: see `SGDD.md` (source design doc, in Portuguese).
This file governs *how* Claude Code should implement it, and reflects
several deliberate departures from the original SGDD made during
development — see "Departures from the SGDD" below. When SGDD and this file
disagree, this file wins.

**This is a living document.** It reflects the architecture as of the
current task sequence (`./prompts`, tasks 1–14, the last landed being
`14-credits.md`). Update it as new tasks land, don't let it drift out of
sync with the actual codebase.

## Before doing anything

At the start of any task:

1. Use the Godot MCP to inspect the actual project structure, existing
   scenes, and their node trees.
2. Read any existing scripts touching the feature you're about to implement.
3. Only then propose a plan. If the real structure differs from what's
   described here, follow the real structure and flag the mismatch instead
   of silently reconciling it.

## Departures from the SGDD

The original SGDD described a level-select map ("tela de seleção de fase")
and a per-level victory screen unlocking the next area. That has been
replaced with a simpler linear flow:

- **No level select screen.** There are exactly 3 stages, played in a fixed
  order: corridor → kitchen → garden. Right now all three
  `LevelManager.STAGE_SCENES` entries point at the same placeholder scene,
  `scenes/1_tower.tscn`, until the kitchen/garden scenes are built.
- **No per-stage victory screen.** Reaching the exit door with all
  objectives complete calls `GameManager.complete_stage()`, which fades to
  the next stage directly (`SceneTransition.goto_scene`). There is no
  "stage complete" prompt scene yet — the SGDD-derived plan for a brief,
  non-interactive prompt has not been implemented; currently the cut is
  just the fade transition. Flag this to the user if a task assumes the
  prompt scene already exists.
- **Credits instead of a 4th victory screen.** Completing the 3rd and final
  stage (`LevelManager.is_last_stage()`) skips straight to
  `scenes/credits_screen.tscn` via `GameManager.trigger_game_complete()`.
- **Defeat screen has two actions**, not the SGDD's single "restart":
  "Continuar" (retry the current stage) and a main-menu button that asks
  for confirmation ("Todo o progresso será perdido...") before quitting the
  run. Both `DefeatScreen` and `CreditsScreen` are thin subclasses
  (`extends "res://scripts/base_end_screen.gd"`) that instance the shared
  `scenes/base_end_screen.tscn` and wire `primary_action_requested` to
  different `GameManager` calls — see Architecture conventions.
- **Guard patrol "look around" behavior is planned but not yet built.**
  The current guard (`Knight`) state machine only has `Idle`, `Patrol`,
  `Alert`, and `Alert` is a stub (`_process_alert()` just zeroes velocity —
  no actual chase/search logic yet). A shared look-around
  state/component, reused by patrolling and stationary guards, is future
  work (referenced informally as "task 16" in planning) — don't assume it
  exists.
- **Detection does not currently implement the per-guard 8-second grace
  timer described in the original task 3 prompt.** `knight.gd`'s
  `_update_detection()` emits `EventBus.player_detected` /
  `EventBus.player_lost` immediately, symmetrically, based on the current
  frame's line-of-sight check — there is no grace timer, no "remembers for
  8s" delay on the signal itself. The "remembering" behavior the SGDD
  wants instead lives one layer up, in `SuspicionManager`: suspicion rises
  toward 1.0 over `time_to_max` (2.0s default) while *any* guard has line
  of sight (guards are aggregated into a `_watchers` dict, so switching
  between two guards' cones doesn't reset progress), and drains back down
  over `time_to_drain` (4.0s default) once no guard can see the player.
  Reaching 1.0 suspicion is what actually triggers capture
  (`EventBus.player_captured`), not raw detection. If a task assumes
  `player_lost` is delayed/debounced, it isn't — check `SuspicionManager`
  instead.

## Language convention

The SGDD is written in Portuguese. **All code, node names, file names,
class names, signals, and comments must be in English.** Use this glossary
for consistent translation across the whole codebase:

| SGDD term (PT-BR)              | Code term (EN)                     |
|---------------------------------|-------------------------------------|
| Manuela                         | `Player` (`player.gd`, `player.tscn`) |
| guarda                          | **`Knight`** (`knight.gd`, `knight.tscn`) — see note below |
| cone de visão                   | `VisionCone` (child `Node2D` of `Knight`, holds a `Polygon2D`; not its own script/scene) |
| barra de suspeita                | `SuspicionBar` (HUD node) / `SuspicionManager.suspicion` (autoload) |
| poção de invisibilidade          | `InvisibilityPotion` (`invisibility_potion.tscn`, item_id `&"invisibility_potion"`) |
| saco de vento                   | `WindBag` (`wind_bag.tscn`, item_id `&"wind_bag"`) |
| apagar velas / archotes         | `.extinguish()` on `Candle` or `BaseIlluminationAsset` (torches included) / `EventBus.candles_extinguished` |
| sub-objetivos / objetivos       | `Objective` (base resource) / `KeyDoorObjective` / `LevelObjectives` |
| chave / porta trancada          | `Key` item (`key.tscn`) / `ExitDoor.set_locked()` — see note below |
| fase                             | `Stage` in prose and this doc; the code itself mixes `Stage` (`GameState.STAGE_COMPLETE`) and `Level` (`LevelManager`, `LevelObjectives`, `level_completed` signal) — both refer to the same concept, not two different ones |
| tela de vitória                 | (removed — see Departures above)    |
| tela de derrota                 | `DefeatScreen` (extends `BaseEndScreen`) |
| olhar ao redor (look around)    | not yet implemented — see Departures above |

**Naming drift to flag, not silently fix:**
- The glossary originally planned `guarda` → `Guard`, but every guard
  script/scene/node in the actual codebase is named **`Knight`**
  (`scripts/knight.gd`, `scenes/knight.tscn`, node name `Knight`). Treat
  `Knight` as the canonical current term — don't introduce a parallel
  `Guard` name, and don't silently rename `Knight` → `Guard` without
  checking with the user first, since it touches multiple `.tscn` files.
  Comments and task prompts still say "guard" in prose; that's fine, it's
  only the code identifiers that are `Knight`.
- There is no standalone `LockedDoor` scene/script. Locking lives on
  `ExitDoor` itself (`set_locked()` / `unlock()`, driven by
  `LevelObjectives` when a `KeyDoorObjective` targets that door). A locked
  `ExitDoor` blocks line of sight (Vision Blockers physics layer) but never
  blocks movement. Its visual is a `Sprite2D` (`$Sprite2D`, not the
  ColorRect placeholder from earlier tasks) swapped between
  `CLOSED_TEXTURE`/`OPEN_TEXTURE` (`sprites/assets/door/door-closed.png` /
  `door-open.png`) in `_update_visual()`, driven by the same `_locked`
  bool — so a door with no `KeyDoorObjective` targeting it (unlocked by
  default) renders as permanently open, and a locked one only shows open
  once its key is picked up and `unlock()` fires. There's no animation
  here (unlike `BaseIlluminationAsset`) since the door only ever has these
  two static states. `door-closed.png`/`door-open.png` were manually
  upscaled on disk to 128x64 (4x their original 32x16, same factor as the
  `sprites/assets/wall/` art) — `$Sprite2D` has **no `scale` override**
  now (plain `1.0`, the default, so it's omitted from the `.tscn`), same
  "let the source art's own pixel size drive it, no synthetic
  Godot-side multiplier" rule as the wall/floor textures below.
  `ExitDoor`'s trigger/vision-blocker `RectangleShape2D` is `(128, 64)`
  to match — if the door art is resized again, resize this shape (and
  `NextStageVoid`, next) to match, same as any other sprite-vs-collision
  mismatch (see the low-res-art note below). `ExitDoor` also has a
  `NextStageVoid` `ColorRect` (solid black, local rect roughly
  `(4,4)`-`(60,60)`, drawn *before* `$Sprite2D` so the sprite's opaque
  door-frame pixels paint over any overhang) toggled by `_update_visual()`
  to `visible = not _locked` — it shows through `door-open.png`'s
  transparent gap between the two door-frame posts, standing in for "the
  next stage" beyond the doorway. Its bounds are computed from the *same*
  eyeballed fractional estimate of where the gap sits (originally guessed
  against the 32x16 source, no screenshot tool available to verify
  against the rendered result), just rescaled proportionally to the new
  128x64 art — nudge the offsets in `exit_door.tscn` if it doesn't line
  up with the actual gap. In `1_tower.tscn`, `ExitDoor.position` is `(1144, 16)` —
  this was repositioned outside this session (flagged as intentional by
  the harness), so treat it as the current source of truth rather than
  the `(1138, -32)` value from an earlier pass; the door art is a
  self-contained archway (see `door-closed.png`), not something that
  needs to align with the top border wall band.
- The `sprites/itens/` asset folder is named in Portuguese ("itens" =
  "items"), inconsistent with the English-only convention. Left as-is
  since renaming would break `.import` references and scene UIDs; flag
  rather than silently renaming if you touch that folder.

## Project structure

Verify against the real repo via MCP before relying on this — this is the
structure as of task 14. Unlike earlier drafts of this doc, scenes and
scripts are **flat** (no `ui/`, `player/`, `enemies/`, `stages/`,
`interactables/`, `powerups/` subfolders) — everything lives directly under
`scenes/` and `scripts/`.

```
res://
  scenes/
    main_menu.tscn            (Jogar / Sair — no "Fases" button)
    hud.tscn
    base_end_screen.tscn      (shared end-of-run overlay template)
    defeat_screen.tscn        (instances base_end_screen.tscn)
    credits_screen.tscn       (instances base_end_screen.tscn; shown only after stage 3)
    base_map.tscn             (shared background + border template; floor
                                 tiled from sprites/assets/wall/floor.png,
                                 borders tiled from the wall sprites — see
                                 Architecture conventions)
    base_wall.tscn            (resizable wall, instanced per stage; booted
                                 base by default via wall.gd's
                                 connects_to_wall export — see Architecture
                                 conventions)
    base_item.tscn            (shared pickup template: sprite + Area2D
                                 (32x32 trigger) + pickup sound)
    key.tscn                  (instances base_item.tscn, item_id "key")
    invisibility_potion.tscn  (instances base_item.tscn, item_id "invisibility_potion")
    wind_bag.tscn             (instances base_item.tscn, item_id "wind_bag")
    candle.tscn                (placeholder ColorRect candle; group "illumination")
    base_illumination_asset.tscn (shared template: AnimatedSprite2D with a
                                 looping "lit" animation and a static "blown"
                                 frame; group "illumination")
    candle1.tscn, candle2.tscn (instance base_illumination_asset.tscn, real
                                 sprite candles from sprites/assets/candleX/)
    torch1.tscn, torch2.tscn   (instance base_illumination_asset.tscn, real
                                 sprite torches from sprites/assets/torchX/)
    exit_door.tscn
    knight.tscn                (see Language convention note on naming)
    player.tscn
    1_tower.tscn                (the one stage scene that currently exists; reused
                                 as a placeholder for all 3 LevelManager.STAGE_SCENES
                                 entries until kitchen/garden scenes are built;
                                 places 4 candle1/candle2 + 8 torch1/torch2 —
                                 see illumination placement note below. Does
                                 NOT place candle.tscn anymore.)
  scripts/
    event_bus.gd, game_manager.gd, level_manager.gd, scene_transition.gd,
    suspicion_manager.gd        (autoloads — see Architecture conventions)
    player.gd, knight.gd
    base_item.gd, exit_door.gd, candle.gd, base_illumination_asset.gd, wall.gd
    objective.gd, key_door_objective.gd, level_objectives.gd
    hud.gd, main_menu.gd
    base_end_screen.gd, defeat_screen.gd, credits_screen.gd
  sprites/
    itens/key/, itens/potion/, itens/wind_bag/   (pickup sprite sheets)
    knight/, player/                              (character sprite sheets)
    ui/                                            (suspicion bar textures)
    assets/candle1/, assets/candle2/               (candlestick_*.png idle
                                 frames + blown_candlestick*.png, 16x16)
    assets/torch1/, assets/torch2/                 (torch/side_torch_*.png
                                 idle frames + blown_*.png, 16x16)
    assets/door/                                   (door-closed.png /
                                 door-open.png, 32x16 — wired into ExitDoor's
                                 Sprite2D, see Departures/Architecture notes)
    assets/wall/                                   (floor.png 64x48;
                                 interior-wall.png / exterior-wall.png
                                 64x17, horizontal tiling; sidewall.png 7x71
                                 / side-exterior-wall.png 7x16, vertical
                                 tiling — see Architecture conventions)
  sounds/                       (currently empty — audio hooks exist as
                                 AudioStreamPlayer(2D) nodes with null
                                 streams; see Audio/art hooks below)
```

No `resources/stages/` `.tres` config files exist — `LevelObjectives`
objectives are authored directly as an exported `Array[Objective]` on the
`LevelObjectives` node in each stage scene, not as external resource files.

## Architecture conventions

- **Autoloads (singletons)**, declared in `project.godot` in this order:
  `EventBus`, `SuspicionManager`, `GameManager`, `LevelManager`,
  `SceneTransition`.
  - `GameManager` — current run state via `enum GameState { PLAYING,
    STAGE_COMPLETE, GAME_COMPLETE, DEFEAT }`. Key methods:
    `restart_level()` (reloads the *current* stage via
    `LevelManager.current_stage_index`), `complete_stage()` (branches on
    `LevelManager.is_last_stage()` — mid-run stages advance and fade to
    the next stage, the last stage calls `trigger_game_complete()`
    instead), `trigger_defeat(guard)` (connected to
    `EventBus.player_captured` in `_ready()`), `quit_to_main_menu()`
    (resets suspicion + stage index, used by the defeat screen's confirm
    flow and by `CreditsScreen`'s primary button). Also owns
    `should_show_item_instructions(item_id)`, a one-shot-per-process
    dictionary so pickup instructions only show once per playthrough even
    across stage restarts.
  - `LevelManager` — keeps its historical name but is linear-only now:
    `current_stage_index`, `total_stage_count`, `is_last_stage()`,
    `advance_to_next_stage()`, `get_current_stage_path()`. **Note:** it
    still carries `unlock_level()` / `is_level_unlocked()` /
    `_unlocked_levels` left over from a pre-linear level-select design —
    these are unused dead code now that there's no level select screen.
    Flag before removing them (in case a future level-select task revives
    them) rather than deleting silently.
  - `SuspicionManager` — the actual "grace period" implementation (see
    Departures above). Not mentioned in earlier drafts of this doc; it's
    an autoload, not a HUD-only concept. Exposes `suspicion: float`,
    `suspicion_changed(value)` signal, `report_visibility(guard,
    sees_player)` (called every physics frame by each `Knight`), and
    `reset()`.
  - `SceneTransition` — reusable fade-to-black scene switcher. Other
    systems call `SceneTransition.goto_scene(path)` instead of
    `get_tree().change_scene_to_file()` directly, so every transition gets
    the same fade (`fade_duration`, default 0.25s) in one place.
  - `EventBus` — global signal hub, no state. Actual current signals:
    `player_detected(guard)`, `player_lost(guard)`,
    `objective_completed(objective_id)`, `level_exited()` (declared but
    currently unemitted — dead signal, don't assume something fires it),
    `level_completed()` (emitted by both `complete_stage()` and
    `trigger_game_complete()` — despite the name it covers both "advance
    to next stage" and "whole game done"), `player_captured(guard)`,
    `item_picked_up(item_id, pickup_message, instructions)`,
    `item_consumed(item_id)`, `power_up_activated(item_id, duration)`,
    `power_up_expired(item_id)`, `candles_extinguished()`. There is no
    separate `stage_exited` / `stage_completed` pair — that was an earlier
    draft's naming; the real signal is `level_completed`.
- **Signals over polling.** `Knight` reports visibility to
  `SuspicionManager` and emits detection signals on `EventBus`; the HUD and
  other systems listen rather than poll guard state.
- **State machines**:
  - `Knight` (`enum State { IDLE, PATROL, ALERT }`): `IDLE` if it has fewer
    than 2 patrol waypoints, `PATROL` otherwise (waypoints are collected
    from a child `PatrolRoute` node's `Marker2D` children, not a dedicated
    `PatrolMarker` scene). `ALERT` is currently a stub — no
    chase/search behavior yet. No `LookAround` state exists yet (see
    Departures above).
  - `Player` (`enum State { IDLE, WALKING }`): only two states. There is
    **no** separate `Drinking` state — drinking the invisibility potion
    (`_drink_invisibility_potion()`) and using the wind bag
    (`_use_wind_bag()`) are instantaneous one-shot actions triggered by
    input, not states the player sits in. Invisibility itself is tracked
    as a plain `_invisible: bool` + `Timer`, independent of `State`.
- **Composition for objectives.** `LevelObjectives` holds an exported
  `Array[Objective]`; `Objective` is a base `Resource` (`id`, `label`,
  `is_complete`, `complete()`). The only concrete subtype implemented so
  far is `KeyDoorObjective` (`key_item_id`, `door_path`), which
  `LevelObjectives._setup_key_door_objective()` wires to lock/unlock an
  `ExitDoor` when the matching item is picked up. Adding an objective type
  means adding a new `Objective` subclass + a `_setup_*` branch in
  `LevelObjectives._ready()`, not per-stage hardcoded logic.
- **Power-ups as timed modifiers, not permanent state.** Invisibility is a
  `Timer` + bool on `Player`, cleared on timeout via
  `EventBus.power_up_expired`. The wind bag is a one-shot consumable, not
  timed — it calls `extinguish()` on every node in the `"illumination"`
  group, which in turn emits `EventBus.candles_extinguished`; every `Knight`
  listens for that and permanently dims its own vision range/angle by
  `dimmed_vision_multiplier` (default 0.75) the first time it fires
  (`_dimmed` guard prevents re-dimming). The group was renamed from
  `"candle"` to `"illumination"` when torches were added, since it now
  covers both candles and torches — `EventBus.candles_extinguished` itself
  was *not* renamed to match (same "name no longer covers everything it
  fires for" drift already noted for `level_completed`; flag before
  renaming rather than doing it silently).
- **Illumination assets (candles/torches) share a base scene, not a base
  script alone.** `base_illumination_asset.tscn` (root `Node2D`, group
  `"illumination"`, script `base_illumination_asset.gd`) declares a single
  `AnimatedSprite2D` child with no `sprite_frames` set. `candle1.tscn`,
  `candle2.tscn`, `torch1.tscn`, `torch2.tscn` each instance that base scene
  (Godot inherited-scene pattern, same as `key.tscn` / `invisibility_potion.tscn`
  instancing `base_item.tscn`) and only override `sprite_frames` on that
  same `AnimatedSprite2D` node with their own `SpriteFrames` — a looping
  `"lit"` animation (4 frames from `sprites/assets/<name>/`) and a
  non-looping single-frame `"blown"` animation (`blown_*.png` from the same
  folder). `extinguish()` on the base script just flips `lit = false` and
  plays `"blown"`. The base script also exports `flip_h: bool` (same
  setter-calls-`_apply_*`-if-`is_node_ready()` pattern as `wall.gd`'s
  `size`), mirroring the sprite horizontally — set per-instance on the
  root node in the Inspector, no need to reach into the child
  `AnimatedSprite2D`. The original `candle.gd`/`candle.tscn` placeholder
  (ColorRect-based, no sprite) still exists as a file but is no longer
  placed anywhere — `1_tower.tscn` now uses the real sprite scenes
  exclusively. **Only candles have collision, not torches** — torches are
  wall-mounted and never reachable, so `base_illumination_asset.tscn`
  (the shared base both inherit) has no collision at all; `candle1.tscn`
  and `candle2.tscn` each add their own `Obstacle` `StaticBody2D`
  (`collision_layer = 1`, "World" only — not Vision Blockers, so candles
  don't obstruct guard sightlines) with a small `RectangleShape2D`
  (`8x8`, offset to `y=11` to sit near the sprite's base rather than its
  flame — sized for the candle sprite's current `scale=2`, so it shrank
  back down along with everything else in the upscale revert below). If a
  future stage needs a reachable/freestanding torch, give it
  the same `Obstacle` treatment rather than adding collision back to the
  shared base (which would also affect wall-mounted torches).
- **`1_tower.tscn` illumination placement**, chosen by sprite semantics
  (`torch1`'s `side_torch_*` frames read as a wall-mounted bracket,
  `torch2`'s `torch_*` frames read as a freestanding torch) rather than
  arbitrary alternation: `torch2` (freestanding) sits at the 2 top-border
  and 2 bottom-border positions (`TorchTopLeft/Right`,
  `TorchBottomLeft/Right`); `torch1` (wall-mounted) sits on both faces of
  each of the two interior pillar walls (`TorchWall1West/East`,
  `TorchWall2West/East`, 4 total). The two `*West` torches set
  `flip_h = true` so they mirror their `*East` counterparts instead of
  both facing the same way. `candle1`/`candle2` alternate across the
  4 quadrants of the open floor between the two interior walls
  (`CandleNW/NE/SW/SE`). This placement was never checked against
  `Knight` patrol routes for path-blocking — now that candles have real
  collision (see above), a future stage's guard patrol could in
  principle walk into one; nothing currently does in `1_tower.tscn`, but
  check this if a patrol route is added or edited near a candle. Every
  `Torch*` instance in `1_tower.tscn` also sets `z_index = -1` — since
  torches have no collision, nothing stops the player from overlapping
  one, and without the override `YSort`'s Y-based ordering (see below)
  would sometimes draw the torch in front of the player depending on
  their exact Y position. `z_index` is checked before Y-sort, so `-1`
  unconditionally keeps every torch behind Player/Knight/everything else
  at the default `z_index = 0` — including `Wall1`/`Wall2`, so a torch's
  sprite draws *behind* the wall pillar it's mounted on wherever they
  overlap, not in front of it. That wasn't explicitly requested and isn't
  visually verified (no screenshot tool); if a wall-mounted torch bracket
  needs to visibly sit on top of its wall instead, this is the tradeoff
  to revisit.
- **Draw order for everything at "player height" goes through a `YSort`
  container, not raw sibling order.** `1_tower.tscn` has a `YSort` `Node2D`
  (`y_sort_enabled = true`) as a direct child of the stage root, and
  `ExitDoor`, `Knight`, `Knight2`, `Player`, `Wall1`, `Wall2`,
  `InvisibilityPotion`, `WindBag`, `Key`, every `Torch*`/`Candle*`, and
  `LevelObjectives` all live under it (not directly under the stage root
  anymore). This exists because `Player`'s visual sprite (192px tall) is
  much taller than its collision box, so without Y-sorting, static
  decoration like a candle would always draw in a fixed front/behind
  order regardless of the player's actual position, looking wrong as they
  walk past it — `y_sort_enabled` reorders draw order by each direct
  child's Y position instead. `LevelObjectives` was moved under `YSort`
  too (not because it needs sorting — it's a non-visual `Node` — but
  because its `KeyDoorObjective.door_path` is the relative `NodePath`
  `"../ExitDoor"`, which only resolves if `LevelObjectives` and
  `ExitDoor` stay siblings). **Deliberately excluded** from `YSort`:
  `Background`/`TopBorderWall`/`BottomBorderWall`/`LeftBorderWall`/
  `RightBorderWall`/`MapBorder` (they're `base_map.tscn`'s fixed
  backdrop, always children of the stage root directly — including them
  in Y-sort would be actively wrong, e.g. `BottomBorderWall` sits at
  `y=710`, so it would draw in front of the player at almost every
  reachable position) and `HUD` (a `CanvasLayer`, not part of the 2D
  scene tree's draw order at all). Any future stage scene that reuses
  this pattern needs its own `YSort` node — it's per-stage-scene, not
  something `base_map.tscn` provides.
- **Floor and walls are tiled `TextureRect`s, not `Sprite2D`s.** All of
  `sprites/assets/wall/` (`floor.png`, `interior-wall.png`,
  `exterior-wall.png`, `sidewall.png`, `side-exterior-wall.png`) is small
  and meant to repeat, so every visual for floor/walls uses
  `TextureRect` with `stretch_mode = 1` (`STRETCH_TILE`) instead of
  scaling like the item/illumination sprites do. `base_map.tscn`'s
  `Background` tiles `floor.png` across the full 1280x720; its 4 border
  edges got dedicated `TextureRect` siblings (`TopBorderWall` /
  `BottomBorderWall` using `interior-wall.png` / `exterior-wall.png`
  tiled horizontally, `LeftBorderWall` / `RightBorderWall` using
  `sidewall.png` tiled vertically) sized to match the existing
  `MapBorder` physics extents — the physics itself (one `StaticBody2D`
  with 4 `CollisionShape2D`s) is untouched. These border visuals are
  bespoke to `base_map.tscn`, not routed through `wall.gd`, since the map
  border is always exactly 1280x720 and never resized.
  Corner draw order at the 4 border seams is deliberately layered via
  `z_index`, not file/sibling order (which is fragile here — `1_tower.tscn`
  carries its own per-instance override blocks for these same nodes, and
  Godot's editor has a habit of rewriting those independently of
  `base_map.tscn`'s internal node order; same reasoning as `Torch*` vs
  `Player` in `1_tower.tscn`): `TopBorderWall` stays at the default `0`,
  `LeftBorderWall`/`RightBorderWall` are `z_index = 1` (draw over top),
  `BottomBorderWall` is `z_index = 2` (draws over both sides). This exact
  ordering — sides over top, bottom over sides — was explicit user intent
  stated in two corrections, not a symmetric "sides always win" rule; if
  a future stage's corners need different layering, don't assume this
  pattern generalizes.
- **`STRETCH_TILE` shows a partial repeat if a border `TextureRect`'s size
  isn't a clean multiple of its texture's native size — this reads as a
  foreign texture stuck onto the wall, not an obvious stretching
  artifact. This has recurred at least twice on `TopBorderWall`
  specifically** (fixed, then drifted back to the same broken shape a
  session later — `offset_bottom` pinned around 68-78 while `offset_top`
  reverted to inheriting `-10` from `base_map.tscn`, someone/something
  re-editing the override without touching both edges together). Each
  time, the fix is the same: set `offset_top = 0` / `offset_bottom = 68`
  on `1_tower.tscn`'s `TopBorderWall` override — an exact single tile
  matching `interior-wall.png`'s native 68px height, no partial second
  repeat. `BottomBorderWall` is the reference for "correct" (`648` to
  `716`, exactly 68 tall) and hasn't drifted. **User-stated design rule,
  explicit**: only sidewalls (`LeftBorderWall`/`RightBorderWall`,
  vertical) are expected to show any "bottom" tiling behavior at all —
  `TopBorderWall`/`BottomBorderWall` (horizontal) must never visibly show
  anything resembling a second/partial tile, full stop. If this recurs a
  third time, consider that hand-editing in the Godot editor is what
  keeps reintroducing it (this project's user actively drags border
  sizes there), and either a defensive clamp script or a stronger
  scene-level convention may be warranted instead of another one-off
  offset fix — but don't add that proactively without being asked, since
  a clamp would fight the user's own manual resizing mid-session.
  **Not yet fixed, not flagged by the user**: `LeftBorderWall`'s height
  (`740` as of last check, per its `1_tower.tscn` override) isn't a clean
  multiple of `sidewall.png`'s native height (`284`) either — same bug
  class, less visually obvious since it's a partial repeat of a
  mostly-uniform vertical pattern against itself. Per the rule above,
  this one may be lower priority/acceptable (side walls "having a
  bottom" is expected), but if a seam shows up there, this is why.
  General rule for any future border resize: pick `offset_top`/
  `offset_bottom` (or `offset_left`/`offset_right` for verticals) so the
  span is an exact multiple of the texture's native pixel size in that
  axis — check both the override *and* what it's actually inheriting
  from `base_map.tscn`, since a stray override on one edge while the
  other stays inherited is exactly how this keeps happening.
- **`wall.gd`'s depth texture is a `Boot` at the *bottom* of the wall, not
  a cap at the top** (this was flipped after an initial wrong pass — if
  you see references to a top "cap," they're stale). Whether it shows at
  all is a `connects_to_wall` export, not auto-detected. `base_wall.tscn`
  (used for the resizable interior pillar walls, e.g. `Wall1`/`Wall2` in
  `1_tower.tscn`) renders as two stacked `TextureRect`s — `Body`
  (`sidewall.png`, tiled, spans from the top down) and `Boot`
  (`side-exterior-wall.png`, anchored to the *bottom* edge so it reads as
  the wall's foundation "planting" it into the floor) — both resized by
  `_apply_size()` alongside the collision shape, same trigger pattern as
  the `size` export. The boot's on-screen height is read directly off the
  texture at runtime (`boot.texture.get_height()`, cast to `float` —
  GDScript's strict-typing check in this project errors, not warns, if a
  ternary mixes `int`/`float` branches) rather than a hardcoded constant,
  so it tracks whatever `side-exterior-wall.png` actually is on disk.
  `connects_to_wall: bool` (default `false`) hides `Boot` and lets `Body`
  fill the whole height when true. Nothing currently sets it to `true` —
  the only walls placed so far (`Wall1`, `Wall2`) are freestanding
  pillars, so they keep the default booted look. It exists for a future
  wall that's placed flush against another wall (e.g. an L-shaped
  corridor), where a boot would look wrong — don't remove it as unused.
- **A `BaseWall`'s `position` is its *base* (bottom-center), not its
  visual center — this matters because of `YSort`.** `Y-sort` compares
  each node's raw `position.y`, not its bounding box; the wall used to
  report its centroid as that position, so a `Player` walking alongside
  the full height of a pillar would sort behind it for the top half
  (`player.y < wall_center.y`) and in front for the bottom half
  (`player.y > wall_center.y`) — visibly flipping mid-pillar, which reads
  as broken since nothing about the player's depth actually changed.
  `wall.gd._apply_size()` now anchors `top_left` at
  `Vector2(-size.x/2, -size.y)` (extends upward from `position`) instead
  of `-size/2`, and `Boot`/`Body`/`CollisionShape2D` all get repositioned
  relative to that — so `Wall1`/`Wall2`'s `position.y` is now `553`
  (their bottom collision edge) rather than `366` (their old center);
  `1_tower.tscn` was updated to match. If a future wall is placed via
  `base_wall.tscn`, remember `position` means "where its base sits," not
  "where its middle sits" — matches how `Player`'s own origin sits near
  its feet, which is what makes Y-sort work at all.
- **There is no Godot-side upscale mechanism anymore — sizing comes
  entirely from the source art, deliberately.** A prior pass fixed the
  low-res `sprites/assets/` art reading as tiny/blurry ("crumpled") next
  to the 192x192 `Player`/`Knight` sprites by both increasing every
  low-res sprite's `scale` *and* adding a shrink-`size`-then-`scale`-
  back-up trick (`TILE_SCALE`) for the tiled wall/floor textures. That
  mechanism was removed piece by piece as the user manually upscaled each
  batch of source art on disk (confirmed via `sips` each time, ~4x prior
  pixel dimensions): `sprites/assets/wall/` first (`wall.gd` and
  `base_map.tscn`'s border/floor `TextureRect`s dropped `TILE_SCALE`,
  now plain `scale = Vector2(1, 1)`/omitted with `size` set directly to
  the footprint), then `sprites/assets/door/` (`door-closed.png`/
  `door-open.png`, 32x16 → 128x64 — `exit_door.tscn`'s `Sprite2D` scale
  dropped), then `sprites/assets/candle*|torch*/` (16x16 → 64x64 —
  `candle1/2.tscn`/`torch1/2.tscn`'s `AnimatedSprite2D` scale dropped).
  **Only `sprites/itens/` (`key`/`invisibility_potion`/`wind_bag`) is
  still native 16x16** — those three keep their original pre-upscale
  `scale` values and will look small next to everything else until their
  source art gets the same treatment. Apply the exact same fix each time
  more art is upscaled: remove the `scale` override entirely (don't set
  it to a fractional "partial" value), resize the matching collision
  shape, done — don't re-derive a new approach. Collision shapes get
  resized every time a sprite's backing art size changes, in either
  direction — `base_item.tscn`'s shared pickup `RectangleShape2D` is
  `32x32` (matches items' still-native art), `exit_door.tscn`'s is
  `128x64`, and `candle1/2.tscn`'s `Obstacle` collision is `16x16` at
  `y=21` (matches candles' new 64x64 native art at `scale=1`; it was
  `8x8`/`y=11` when candles were still 16x16 at `scale=2` — same physical
  size, just recomputed for the new source resolution). The general rule:
  whenever a sprite's backing art or `scale` changes, re-check anything
  sized to match it (collision shapes, `NextStageVoid`, etc.) — nothing
  keeps them in sync automatically. `project.godot`'s
  `textures/canvas_textures/default_texture_filter=0` (Nearest,
  project-wide) was **not** touched by any of this — that's a
  crispness/filter setting independent of scale magnitude, still correct
  regardless of whether art is upscaled in Godot, on disk, or not at all.
- **`sprites/assets/candle1|candle2|torch1|torch2/` folder *contents* got
  swapped at one point** (outside of any Claude Code edit — discovered
  when `1_tower.tscn` suddenly threw missing-resource errors for all four
  scenes) — `candle1/` briefly held the `candlestick_2_*` art that
  belongs to `candle2.tscn` and vice versa, same for `torch1`
  (`side_torch_*`, wall-mounted) / `torch2` (`torch_*`, freestanding).
  Fixed by moving the files back so each folder's name matches its
  content's filename (`candle1/` → `candlestick_1_*`, etc.), confirmed
  with the user this was just an upscale-export side effect and the
  numbered frames should keep their original identity. One asymmetry:
  the two "blown" torch frames picked up a `_1` suffix in the move
  (`blown_side_torch.png` → `blown_side_torch_1.png`,
  `blown_torch.png` → `blown_torch_1.png`) that the numbered frames
  didn't get, so `torch1.tscn`/`torch2.tscn`'s `ext_resource` for the
  `"blown"` animation needed both a new `path` *and* a new `uid` (moving
  a file via plain `mv` preserves the uid embedded in its `.import`
  sidecar; a genuinely new filename doesn't have one to preserve, so its
  `.import` carries a freshly-generated uid — read it with
  `grep '^uid=' <file>.png.import` rather than guessing). If this
  folder/filename mismatch happens again, check for exactly this kind of
  partial rename before assuming it's a clean swap.
- **Detection has a grace period, but it is implemented as suspicion
  aggregation, not a per-signal delay.** See the dedicated Departures
  entry above before writing anything that assumes `player_lost` is
  debounced at the signal level.

## Naming conventions

- Files & folders: `snake_case` (exception: `sprites/itens/` — Portuguese,
  see Language convention note).
- Node names in scene tree: `PascalCase` (Godot default; auto-generated
  helper nodes like `Marker2D2` inside `PatrolRoute` are fine as-is).
- Classes (`class_name`): `PascalCase`. Currently declared:
  `LevelObjectives`, `Objective`, `KeyDoorObjective`, `ExitDoor`,
  `BaseEndScreen`. Most scripts (`player.gd`, `knight.gd`, `hud.gd`,
  `main_menu.gd`, autoloads, etc.) don't declare a `class_name` and are
  referenced by scene/node path instead — that's fine, only add
  `class_name` when something needs to reference the type directly (as
  `LevelObjectives` does with `KeyDoorObjective`).
- Signals: `snake_case`, past tense for events (`player_detected`,
  `objective_completed`, `candles_extinguished`).
- Constants: `SCREAMING_SNAKE_CASE` (e.g. `ARRIVAL_DISTANCE`,
  `MAX_INVENTORY_SIZE`, `CLOSED_TEXTURE`).
- Typed GDScript everywhere feasible (`var suspicion: float = 0.0`,
  `Array[Objective]`, `Array[StringName]`).

## Audio/art hooks

The SGDD calls out specific sound/music cues per action. The established
pattern in this codebase: `@onready` an `AudioStreamPlayer`/
`AudioStreamPlayer2D` node, `print()` a placeholder tag matching the
SGDD's bracket notation (e.g. `[som: beber poção]`, `[som: assoprar]`,
`[som: alerta!]`, `[som: abrir porta]`), and only call `.play()` if
`.stream != null` — so the hook is silent but functional until a real
asset is dropped into the node in the editor. Follow this exact pattern
(print + null-stream guard) for any new sound cue rather than skipping the
hook or inventing a different placeholder mechanism. `sounds/` is
currently empty; every audio node in the project is running on this
placeholder path. This applies to future work on the stage-complete prompt
and any remaining SGDD audio cues too.

## Git discipline

- One feature/system per commit.
- Commit after each task in `./prompts` is verified working via MCP,
  before starting the next one.
- Don't let a single session touch more than 2-3 `.tscn` files without
  committing — merge conflicts in scene files are painful.

## Verification expectation

For every task, after implementation:
1. Run the relevant scene via the Godot MCP.
2. Check the Output/errors panel for warnings or errors.
3. Confirm the specific acceptance criteria from the task prompt.
4. Report back what was verified and what wasn't (e.g. "audio hook added
   but using placeholder sound — visual/logic confirmed working").

Do not report a task as done without having run it.
