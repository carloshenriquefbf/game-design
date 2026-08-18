Read CLAUDE.md. Implement guard patrol behavior.

Note: v0 already has enemy scenes — inspect via MCP before building new
ones.

From the SGDD: guards patrol fixed routes. Art list specifies guard states:
idle, patrolling (really just walking), and alert.
implement patrol and idle now; alert state will be driven by the vision
cone/suspicion system in the next task, but stub the state now.

Requirements:
- Guard state machine: Idle, Patrol, Alert (stub Alert for now).
- Patrol routes defined via waypoints (e.g. Path2D or an array of
  positions) configurable per guard instance in the editor.
- Guard moves along its route and loops/reverses at the end.

Acceptance criteria:
- At least one guard in the existing level scene patrols a defined route
  continuously.
- Verify via MCP: run the level, confirm guard movement matches the
  configured waypoints with no errors.