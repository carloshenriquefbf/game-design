Read CLAUDE.md. Implement the loading screen and a scene transition system.

From the SGDD: "Começa o jogo com a tela de loading exibindo uma tela de
menu principal" — the game starts with a loading screen, then transitions
into the main menu.

Requirements:
- A LoadingScreen scene shown on game start, transitioning to MainMenu.
- A reusable transition method (e.g. on GameManager or a dedicated
  SceneTransition autoload) other tasks can call to switch scenes, so
  later tasks (menu -> level select -> level -> victory/defeat) don't each
  reinvent scene-switching.

Acceptance criteria:
- Running the project shows the loading screen first, then automatically
  transitions to an (even if empty/placeholder) main menu scene.
- Verify via MCP: run the project, confirm no errors, confirm the scene
  tree shows the transition occurred.