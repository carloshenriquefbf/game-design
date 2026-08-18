Read CLAUDE.md. Implement a "look around" behavior on knight.gd — this is
one script driving every guard already, so "reusable" here means one
method called from two states, not a separate component file.

Depends on the current knight.gd (State enum: IDLE, PATROL, ALERT) and its
PatrolRoute/Marker2D waypoint setup and _update_detection() logic. Verify
via MCP that these still match what's described in CLAUDE.md before
starting — inspect knight.gd directly.

Behavior:
- Add State.LOOK_AROUND to knight.gd's State enum, alongside the existing
  IDLE, PATROL, ALERT.
- Patrolling guards (2+ Marker2D waypoints under PatrolRoute, State.PATROL):
  every time the guard arrives at a waypoint (reuse the existing
  ARRIVAL_DISTANCE check already driving patrol arrival), transition to
  LOOK_AROUND, stop moving, perform the sweep, then resume PATROL toward
  the next waypoint.
- Stationary guards (fewer than 2 waypoints, State.IDLE): reuse the exact
  same look-around method, triggered on a periodic timer while IDLE rather
  than on waypoint arrival. Implement this as one method both states call
  into — do not write a second copy of the sweep logic for IDLE.
- The sweep is NOT a full survey of the surroundings. The guard should
  never turn to look behind itself. Cap the sweep to a configurable angle
  (default 45° total) measured from the guard's forward-facing direction
  at the moment LOOK_AROUND starts — a glance side to side, nothing more.
  Do not let this exceed a hard ceiling well short of 90° in either
  direction.
- The VisionCone (child Node2D + Polygon2D on Knight) stays fully active
  during the sweep and rotates with the guard's facing — the player can
  still be detected while a guard is in LOOK_AROUND, this isn't a blind
  state.
- If _update_detection() reports the player is seen at any point during
  LOOK_AROUND, immediately cancel the sweep (stop any tween cleanly, no
  leftover rotation/animation state) and transition to ALERT — same as
  during normal PATROL. Note ALERT is currently a stub (_process_alert()
  just zeroes velocity); this task does not need to add chase/search
  logic, only make sure the transition into ALERT from LOOK_AROUND is
  clean.
- After the sweep completes (a couple of seconds is reasonable, make it
  configurable), the guard resumes whatever it was doing before: PATROL
  toward the next waypoint, or back to standing still (IDLE) for
  stationary guards.

Requirements:
- Sweep angle cap, sweep duration, and the IDLE periodic timer interval
  should be exported/configurable variables on knight.gd, not hardcoded
  literals.
- No new scene or node type is required — PatrolRoute/Marker2D waypoints
  already exist; LOOK_AROUND is pure logic on the existing Knight script
  and node.
- Follow CLAUDE.md's enum naming convention: SCREAMING_SNAKE_CASE
  (LOOK_AROUND, matching IDLE/PATROL/ALERT), not PascalCase.

Acceptance criteria:
- A patrolling Knight, on reaching each waypoint, visibly stops, sweeps
  within the configured angle (verify it never rotates far enough to face
  where it just came from), then resumes toward the next waypoint.
- A stationary Knight (test with one that has fewer than 2 waypoints)
  performs the same sweep periodically — confirm via code inspection that
  it's calling the same method as the patrolling case, not a duplicate.
- The vision cone continues to detect the player normally throughout the
  sweep (test by having the player stand in the cone's path during
  LOOK_AROUND and confirming EventBus.player_detected still fires and
  SuspicionManager still receives report_visibility(guard, true)).
- Detecting the player mid-sweep cleanly interrupts LOOK_AROUND and
  transitions to ALERT with no stuck animation or leftover rotation state.
- Verify via MCP: observe at least one patrolling Knight and one
  stationary Knight both performing the look-around in a running stage.