Read CLAUDE.md. Implement win/lose flow and progression.

From the SGDD:
- Reaching the exit with all objectives complete -> victory screen
  [música: vitória], unlocking the next level on the map.
- Guard capture -> defeat screen [música: derrota] with option to restart
  the level.

Requirements:
- Exit trigger area in the level that checks: are all objectives (task 12)
  complete? If yes, trigger GameManager's victory state, transition to
  VictoryScreen, and call LevelManager.unlock_level() for the next level.
  If objectives aren't complete, exiting should not succeed (confirm via
  MCP/SGDD whether it should give feedback or simply do nothing — SGDD
  doesn't specify; default to doing nothing, note this as an assumption).
- player_captured (from task 8) triggers GameManager's defeat state and
  transitions to DefeatScreen.
- DefeatScreen has a restart button calling GameManager.restart_level().
- VictoryScreen returns to level select, now showing the next level
  unlocked.

Acceptance criteria:
- Completing all objectives and reaching the exit shows the victory screen
  and unlocks the next level (verify via level select afterward).
- Getting captured shows the defeat screen; restart reloads the level in a
  clean state (suspicion reset, objectives reset, guard positions reset).
- Verify via MCP end-to-end: play through one full level to both a
  victory and a defeat outcome.