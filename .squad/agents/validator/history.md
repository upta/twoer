# Validator — Session History

## Session: Initial Validation Infrastructure

### What was done
- Created `level_harness_controller.gd` — a single reusable controller with `setup_mode` export var controlling 4 fixture configurations (initial, with_units, battle_planning, battle)
- Created 4 harness `.tscn` files that set the mode for each fixture
- Created 5 scenario JSON contracts covering initial state, phase transitions, economy, checkpoint detection (the ANY bug), and mana rewards

### Key learnings
1. **The scenario driver has no `call_harness` operation.** The only way to set up specific game states is through harness configuration at load time. Different test fixtures require different harness scenes with pre-configured exported vars.
2. **CHECKPOINT phase is transient.** It immediately transitions to BATTLE_PLANNING in `_on_phase_changed`. Assertions should check for BATTLE_PLANNING, not CHECKPOINT.
3. **Deployment is timer-based (3s intervals).** Frame-based waits need generous margins. 450 frames (~7.5s at 60fps) gives enough time for the first Swarm (speed=100) to deploy (3s) and travel from x=50 to x=400 (3.5s).
4. **Tutorial level lanes 2 and 3 have no defenses.** These are the ideal lanes for deterministic movement tests — units won't be blocked by walls or attacked by towers.
5. **The checkpoint detection code reads checkpoint_x from lane 0 regardless of unit lane.** This means the checkpoint position is always 400 for first checkpoint, independent of where units are deployed.
6. **Scenarios 4 and 5 (checkpoint_detection, mana_checkpoint) will FAIL with the current `all_past` code in level.gd.** This is by design — they validate the desired ANY-unit behavior that hasn't been implemented yet.

### Files created
- `src/validation/scripts/harness_controllers/level_harness_controller.gd`
- `src/validation/harnesses/level_harness.tscn`
- `src/validation/harnesses/level_with_units_harness.tscn`
- `src/validation/harnesses/level_battle_planning_harness.tscn`
- `src/validation/harnesses/level_battle_harness.tscn`
- `src/validation/scenarios/initial_state.json`
- `src/validation/scenarios/phase_transition.json`
- `src/validation/scenarios/buy_units.json`
- `src/validation/scenarios/checkpoint_detection.json`
- `src/validation/scenarios/mana_checkpoint.json`
