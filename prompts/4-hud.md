Read CLAUDE.md. Implement the HUD.

From the SGDD's art/interface list: suspicion bar, active power-up icon
(potion / wind bag), and inventory (key to the door) and a sub-objectives progress indicator. The sprites will be added later, just create areas with backgrounds for now.

Requirements:
- Visual suspicion bar bound to the suspicion value (updates
  live, doesn't just show at the end).
- Power-up icon area that can show/hide an active power-up icon (wire it up
  as an empty/hidden placeholder for now following 1 will feed it
  real state).
- Objective indicator showing progress (e.g. "grab key / escape through the door") —
  wire to a placeholder/stub value for now;

Acceptance criteria:
- Suspicion bar visibly fills/drains in sync with task 8's suspicion value
  during actual gameplay testing.
- HUD elements render without layout issues at the target resolution.
- Verify via MCP.