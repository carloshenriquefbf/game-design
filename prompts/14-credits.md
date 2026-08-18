Read CLAUDE.md. Implement a credits scene shown after all 3 stages
(corridor, kitchen, garden, which for now is only 1_tower since the new stages will come in a later task),  have been completed.


Requirements:
- In the exit-trigger logic from task 13, the branch for "objectives
  complete AND is_last_stage() == true" should, instead of the normal
  stage-complete-prompt-then-advance behavior:
  - Trigger GameManager's game-complete state.
  - Transition (task 1's system) directly to a new CreditsScreen. No
    stage-complete prompt, no per-stage victory screen — reaching the door
    on stage 3 with objectives done goes straight to credits.
- CreditsScreen: static credits display (you have successfully escaped from the tower etc etc),
  with a button to return to the main menu.
- After credits, returning to main menu and pressing Play again should
  restart from stage 1 (the game has been fully completed, there's nothing
  left to "continue" toward) — reset current_stage_index to 0 as part of
  entering the game-complete state, or when Play is pressed after
  game-complete is true, whichever fits your GameManager structure better.

Acceptance criteria:
- Completing stage 1 auto-advances to stage 2 via the stage-complete
  prompt, as in task 13 — no credits screen appears.
- Completing stage 2 auto-advances to stage 3 the same way.
- Completing stage 3 (reaching the door with all objectives done) skips
  the stage-complete prompt entirely and shows CreditsScreen.
- In our case we will finish stage 1 three times to test.
- From CreditsScreen, returning to main menu and pressing Play starts
  stage 1 again from a clean state.
- Verify via MCP: play through all 3 stages in sequence and confirm
  CreditsScreen appears only after the 3rd, with no intermediate victory
  or stage-select screens anywhere in the run.