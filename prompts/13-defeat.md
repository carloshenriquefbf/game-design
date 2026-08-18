Read CLAUDE.md. Extend the DefeatScreen built in the previous task.

Requirements:
- "Continue" button: retries the CURRENT stage (per task 13's
  current_stage_index) from a clean state — suspicion reset, objectives
  reset, guard positions reset, player back at the stage's start position.
  Same as GameManager.restart_level().
- "Quit to Main Menu" button: transitions back to MainMenuScreen (reuse the
  transition system from task 1). This abandons the current stage attempt
  entirely — do NOT change current_stage_index or otherwise touch
  LevelManager's progression state; only in-run state (suspicion,
  objective progress, guard state for that attempt) should be discarded.
  Since there's no level select, re-entering "Jogar" from the main menu
  after this should restart from stage 1. Ask if the user is sure, as all progress will be lost.
- Both buttons should play the placeholder click sound established in
  task 2, for UI consistency.
- Keep GameManager's defeat state machine as-is (task 13); this task only
  changes what DefeatScreen's UI offers and where each button routes.

Acceptance criteria:
- On the defeat screen, both buttons are present and clearly distinct.
- Continue reloads the same stage in a clean state (verify via MCP: check
  suspicion is 0, objectives are unclaimed, guards are back at patrol start
  positions).
- Quit to Main Menu returns to the main menu, changing
  current_stage_index
- Verify via MCP end-to-end for both button paths.