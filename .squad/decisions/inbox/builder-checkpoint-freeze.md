### 2026-05-08: Battlefield Freeze Pattern for Phase Transitions

**By:** Builder (Core Developer)

**What:** During non-BATTLE phases, the entire Battlefield node tree is frozen using `battlefield.process_mode = Node.PROCESS_MODE_DISABLED`. This stops all units, towers, and walls from processing. UI remains responsive because it lives in a separate CanvasLayer.

**Why:** Per-unit state checks are fragile and require touching every entity type. `process_mode` is Godot's built-in mechanism for bulk pause and propagates to all children automatically. The `else` branch in `_on_phase_changed()` catches all non-BATTLE phases (INITIAL_PLANNING, CHECKPOINT, BATTLE_PLANNING, LEVEL_COMPLETE) so no new phase can accidentally leave the battlefield running.

**Implications:**
- Any new nodes added under Battlefield will automatically freeze during planning phases
- If we ever need selective freeze (e.g., towers keep shooting during planning), we'd need to restructure
- Win/lose signals still fire because level.gd's `_physics_process` only runs during BATTLE phase anyway
