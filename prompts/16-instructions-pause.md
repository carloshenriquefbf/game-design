Read CLAUDE.md. Implement two related pieces: a shared instructions
component, and a pause menu that uses it as a modal.

Note: per CLAUDE.md, main_menu.tscn currently only has Jogar / Sair — there
is no existing Instructions screen or button. This task adds one. Verify
via MCP first in case this has changed since CLAUDE.md was last updated.

### Part A — shared instructions content

Build the item explanations as a standalone, reusable piece (e.g.
`instructions_content.tscn` / `.gd`) — NOT duplicated per-container. It
needs to render correctly both full-screen and inside a small modal, so
keep it a self-contained scrollable/flexible layout without assumptions
about the size of whatever contains it.

Content: explain each item and how to use it —
- Key (`key.tscn`): what it's for, that it unlocks the matching ExitDoor.
- Invisibility Potion: what it does, that it's a timed effect, how it's
  triggered (per player.gd's `_drink_invisibility_potion()` — confirm the
  actual input binding via MCP rather than guessing).
- Wind Bag: what it does (extinguishes candles, dims nearby guards'
  vision), how it's triggered (`_use_wind_bag()` — same note, confirm the
  input binding).
Use simple placeholder icons/text if final art isn't ready — this is a
structural task.

Two containers instance this same content scene:
- `instructions_screen.tscn`: full-screen version, opaque/solid background,
  a back button returning to main menu via SceneTransition.
- Add an "Instruções" button to `main_menu.tscn`, alongside Jogar / Sair,
  that transitions to `instructions_screen.tscn`.

### Part B — pause menu

`pause_menu.tscn` / `.gd`, instanced in stage scenes alongside `hud.tscn`
(there's currently one stage scene, `1_tower.tscn` — add it there; note for
whoever builds the kitchen/garden stages that it needs to be added there
too).

- Triggered by a pause input action (check InputMap via MCP — if there's
  no existing "pause" action bound to Escape, add one; don't hardcode the
  key directly in code).
- On trigger: `get_tree().paused = true`. Everything in the background
  (Knight AI, Player, SuspicionManager timers, animations) must actually
  stop — leave their `process_mode` at the default (`PROCESS_MODE_INHERIT`)
  so pausing the tree freezes them. Only the PauseMenu itself (and its
  buttons) needs `process_mode = PROCESS_MODE_ALWAYS` (or `WHEN_PAUSED`) so
  it stays interactive while the tree is paused.
- UI: exactly 4 buttons, stacked vertically, nothing else — "Continuar" /
  Continue, "Instruções" / Read Instructions, "Menu Principal" / Quit to
  Main Menu, "Sair do Jogo" / Quit Game. Cover/dim the background enough
  that only these 4 buttons read as the active UI (a semi-opaque full-screen
  panel behind the button column is enough — doesn't need to be pure black).
- Button behavior:
  - **Continue**: unpause (`get_tree().paused = false`) and hide the pause
    menu. This is a different action from DefeatScreen's "Continuar" —
    that one restarts the stage; this one just resumes. Don't reuse
    `GameManager.restart_level()` here, name the method distinctly (e.g.
    `resume_game()`) to avoid confusion.
  - **Instruções**: do NOT unpause. Instead open
    `instructions_modal.tscn` — a second container instancing the same
    `instructions_content.tscn` from Part A, but as a small centered panel
    with a translucent/semi-transparent background that does NOT fill the
    full width/height of the screen (visibly smaller than the screen, game
    still dimly visible behind it), with a close button returning to the
    4-button pause menu (still paused throughout).
  - **Quit to Main Menu**: unpause first, then call
    `GameManager.quit_to_main_menu()` and transition via
    `SceneTransition.goto_scene()`. No confirmation dialog is required for
    this — DefeatScreen has one for its quit action, this task doesn't
    replicate that unless you think consistency matters enough to flag it
    to the user first; default to no confirmation here.
  - **Quit Game**: `get_tree().quit()`.
- Buttons play the existing placeholder click sound pattern (see
  CLAUDE.md's Audio hooks section) for consistency with other menus.

Requirements:
- Instructions content exists in exactly one scene, instanced (not copied)
  by both the full-screen version and the modal version.
- Pause menu buttons follow CLAUDE.md's naming conventions (snake_case
  methods, PascalCase nodes).

Acceptance criteria:
- Main menu now has a working Instructions button leading to a full-screen
  instructions view with a working back button.
- Pressing the pause input during gameplay pauses everything in the
  background (guard movement, patrol/look-around, suspicion changes) and
  shows exactly the 4 vertically-stacked buttons.
- Continue resumes gameplay exactly where it left off (verify a guard mid-
  patrol resumes its route, not resets).
- Instruções from the pause menu opens a modal that is visibly smaller
  than the full screen, semi-transparent, showing the same content as the
  main menu's instructions screen — confirm via MCP/code inspection that
  it's the same instanced content scene, not a duplicate.
- Quit to Main Menu and Quit Game both work correctly from the paused
  state (verify the tree is unpaused before the main-menu transition, so
  the main menu itself isn't stuck paused).
- Verify via MCP end-to-end: pause mid-level, open instructions, close it,
  resume, then pause again and quit to main menu.