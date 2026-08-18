Read CLAUDE.md. Implement the main menu screen.

From the SGDD: main menu has buttons "Jogar" (Play), and
"Sair" (Quit), with a click sound on button press [som: clicar]. Music: tom
tenso (tense opening theme) — hook the AudioStreamPlayer with a placeholder
if the final asset isn't available yet, per CLAUDE.md's audio hook
convention.

Requirements:
- Play button -> transitions to level select screen (stub it if it doesn't
  exist yet, task 3 will build it).
- Sair (Quit) button -> quits the application.
- All buttons play a click sound (placeholder acceptable) on press.

Acceptance criteria:
- All two buttons are present, clickable, and trigger correct behavior.
- Click sound hook fires on each button (verify via MCP/logs, actual audio
  asset can be placeholder).