Read CLAUDE.md. Implement the invisibility potion power-up.

From the SGDD: pickup item; on consumption [som: beber poção], starts a
short timer during which player cannot be detected.

Requirements:
- Pickup-able item in the world (extend/reuse existing pickup patterns from
  v0 if any — check via MCP).
- Triggers player's Drinking sound briefly, then starts an
  invisibility timer.
- While active, detection logic from previous tasks must treat the player as
  non-detectable regardless of vision cone overlap.
- Updates the HUD power-up icon to show active state and
  remaining duration.
- Plays placeholder pickup/drink sound.

Acceptance criteria:
- Picking up the potion adds it to the inventory.
- Drinking up the potion prevents suspicion from increasing even while
  standing directly in a guard's cone, for the timer's duration. Colliding with the body of the guard still triggers game over.
- After the timer expires, normal detection resumes.
- Verify via MCP.