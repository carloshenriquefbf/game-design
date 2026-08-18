Read CLAUDE.md. Implement the per-level objectives system.

From the SGDD: each level has sub-objectives to complete before reaching
the exit, e.g. find a key and open a locked door [som: abrir porta]. An
objective indicator on the HUD shows progress.

Requirements:
- Data-driven Objective system per CLAUDE.md's architecture conventions
  (a level holds a list of objectives, not hardcoded per-level branching
  logic) so future levels can define different objective sets without new
  code.
- Implement the key/locked-door objective type concretely: picking up a
  Key marks that objective complete and unlocks/opens the associated
  LockedDoor; interacting with the door plays the placeholder open sound.
- Emit EventBus.objective_completed on each objective completion, and wire
  the HUD's objective indicator (task 9, currently stubbed) to real
  progress (e.g. "1/2").
- Structure the Objective base so other objective types (not specified yet
  in SGDD) could be added later without reworking this system.

Acceptance criteria:
- Level shows correct total objective count and updates progress when the
  key/door objective is completed.
- Locked door cannot be passed before the key is collected; can be passed
  after.
- Verify via MCP.