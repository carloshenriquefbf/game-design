Read CLAUDE.md. Implement the wind bag power-up.

From the SGDD: used to blow out candles [som: assoprar], which drastically
reduces the vision cone range of guards in that map.

Requirements:
- Wind bag as a pickup/usable item (follow the same pickup pattern
  established in the preveious task for consistency).
- Candle objects placed in the level that can be "extinguished" when the
  wind bag is used near them.
- Extinguishing a candle reduces the cone range/angle (from previous task's
  exported variables) of guards — confirm via MCP/existing level design
- Visual/state change on the candle (lit -> extinguished) and on the
  guard's cone (normal -> reduced), matching the two cone art states from
  the SGDD art list.

Acceptance criteria:
- Using the wind bag extinguishes all candles  and measurably shrinks
  the guards' vision cone range.
- Verify via MCP: confirm cone range value changes and the reduced cone
  makes detection require closer proximity.