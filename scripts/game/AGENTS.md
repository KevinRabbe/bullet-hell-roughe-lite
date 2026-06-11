# Game Orchestration
- Owns run flow, wave/intermission/shop/end-state orchestration.
- Backend state is authoritative; UI must not redefine gameplay truth.
- Keep transition order explicit and stable: combat, intermission, level-up, continue, end-state.
