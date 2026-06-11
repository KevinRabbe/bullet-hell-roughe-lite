# UI Layer
- Owns presentation, input wiring, and view refresh behavior only.
- UI should consume controller or view-model state, not duplicate gameplay rules.
- Favor dirty/event-driven refresh over per-frame full rebuilds.
