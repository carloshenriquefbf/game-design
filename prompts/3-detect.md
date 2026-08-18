Read CLAUDE.md. Implement the guard's vision cone and detection.

From the SGDD: guards have a vision cone drawn in front of them; detection
is by the player entering the cone. Art list specifies normal and reduced
cone states (reduced ties to the wind bag power-up in a later task — just
make cone range/angle configurable now so that task can shrink it).

Important: entering and leaving the cone are NOT symmetric. This is not a
simple in/out toggle:
- Entering the cone starts detection immediately.
- Leaving the cone does NOT immediately end detection. The guard should
  keep "remembering" the player for a grace period of 8 seconds after line
  of sight is lost. Only if the player stays outside the cone continuously
  for the full 8 seconds does the guard fully lose track of them.
- If the player re-enters the cone at any point during those 8 seconds,
  the grace timer resets/cancels and detection continues uninterrupted.

Requirements:
- Visually drawn vision cone (Polygon2D or similar) in front of the guard,
  rotating with the guard's facing direction during patrol (already part of the knight scene, only with one length).
- Angle/distance-based detection: determine when the player is within the
  cone's angle and range, and use a raycast or line-of-sight check so
  walls/obstacles block detection (confirm via MCP whether the existing
  map has collision layers for walls to raycast against).
- On the player entering the cone (line-of-sight becomes true), emit
  EventBus.player_detected. Play the alert sound placeholder
  [som: alerta!] from SGDD.
- On the player leaving the cone (line-of-sight becomes false), start an
  8-second grace timer on that guard. Do NOT emit player_lost yet — this
  is the window task 8's suspicion bar will use to drain gradually rather
  than reset instantly.
- If line-of-sight becomes true again before the grace timer expires,
  cancel the timer; detection is considered continuous.
- If the grace timer completes (8s with no re-detection), emit
  EventBus.player_lost.
- Cone angle and range should be exported/configurable variables (not
  hardcoded) so the wind bag power-up task can reduce them per-guard.
- Expose the grace period (8.0s) as an exported/configurable variable
  rather than a hardcoded literal, in case it needs tuning per guard or
  difficulty later.

Acceptance criteria:
- Walking into a guard's cone triggers player_detected immediately.
- Walking out of the cone does NOT immediately trigger player_lost —
  detection state persists.
- Staying outside the cone for the full 8 seconds triggers player_lost.
- Re-entering the cone at, say, 5 seconds into the grace period cancels
  the timer and does not re-trigger player_detected as a fresh event (it
  was never lost).
- A wall between player and guard prevents detection even inside the
  cone's angle/range.
- Verify via MCP: test all three cases above (leave-and-return before 8s,
  leave-and-stay-out past 8s, wall-blocked line of sight) in the running
  level.