Read CLAUDE.md. Implement stage completion, defeat, and progression.
Progression is fully linear and automatic: reaching the exit with all
objectives done immediately advances to the next stage, no player choice
involved.

Requirements:
- Extend LevelManager with an ordered stage sequence (array of
  level scene paths, 3 entries: corridor (1_tower), kitchen and garden(both coming in a future task, for now treat as if there's only one scene)), a
  current_stage_index, and total_stage_count (3). Expose
  is_last_stage() -> bool and advance_to_next_stage().
- Exit trigger area in the level checks whether all objectives (task 12)
  are complete. If not complete, exiting does nothing.
- If objectives are complete AND this is NOT the last stage:
  - Trigger GameManager's stage-complete state.
  - Automatically transition (reuse transition
    system) directly into the next stage's scene via
    LevelManager.advance_to_next_stage().
- If objectives are complete AND this IS the last stage (stage 3): do NOT
  show the stage-complete prompt described above. Instead, hand off to the
  full-game-completion flow — this is implemented in a future task 15 (Credits).
  This task should just make sure the "is this the last stage" check exists
  and cleanly branches; task 15 owns what happens on that branch.
- Defeat: player_lost still triggers GameManager's defeat
  state and transitions to DefeatScreen. Task 14 defines what's actually
  on that screen — this task just needs GameManager.restart_level() to
  correctly reload the CURRENT stage (by current_stage_index) in a clean
  state: suspicion reset, objectives reset, guard positions reset.

Acceptance criteria:
- Completing stage 1's objectives and reaching the door with the key
  triggers the automatically loads stage 2 —
  no screen requiring a click or selection appears at any point. since stage 2 and 3 will be inserted in a later task, treat 1_tower as the first and last scene.
- Completing last scene's objectives and reaching the door does NOT show the
  stage-complete prompt; it instead sets up for task 15's credits flow
  (task 15 will verify the actual credits screen appears).
- Getting captured on any stage shows DefeatScreen and, on restart, reloads
  that same stage (not stage 1) in a clean state.
- Verify via MCP: play stage 1 through to the automatic stage 2 load.