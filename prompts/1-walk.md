Read CLAUDE.md. Implement/verify Manuela's top-down movement.

Note: the v0 already has a player scene — inspect it via MCP first and
build on what exists rather than replacing it, unless it's fundamentally
incompatible with the conventions in CLAUDE.md.

From the SGDD: top-down view, player moves freely around the map. Art list specifies states: idle and walking, which are already set on the player scene on the AnimatedSprite2D.

Requirements:
- Top-down movement
- Player state machine or state enum with Idle and Walking wired to movement.

Acceptance criteria:
- Player moves smoothly around the existing map scene with correct
  animation state changes (idle <-> walking).
- Verify via MCP by running the level and checking no errors/warnings.