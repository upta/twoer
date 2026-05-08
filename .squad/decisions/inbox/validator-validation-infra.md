# Decision: Validation Infrastructure Design

**Author:** Validator
**Date:** 2025-01-20
**Status:** Implemented

## Context
Brian mandated automated validation coverage. The project had 11 phases of game code with zero scenarios.

## Decisions

### 1. Single controller script with configurable setup modes
Rather than separate controller scripts per harness, a single `level_harness_controller.gd` uses an `@export var setup_mode` to configure four fixture states. This keeps the validation DRY while allowing different `.tscn` files to target specific test conditions.

### 2. Deploy to empty lanes for deterministic battle tests
Tutorial level lanes 2-3 have no defenses. Battle scenarios use `deploy_lane = 2` so units move unimpeded, making checkpoint timing predictable.

### 3. Checkpoint detection scenarios document desired (not current) behavior
Scenarios 4 and 5 assert ANY-unit checkpoint behavior. The current code uses ALL-unit detection (`all_past` in `level.gd`). These scenarios will correctly fail until the bug is fixed, serving as regression tests once resolved.

### 4. Generous frame waits for timing-dependent scenarios
Battle scenarios use 450 frames (~7.5s) to account for deployment timer (3s) + unit travel time (3.5s for Swarm at speed 100 from x=50 to x=400) + safety margin.

## Risks
- Frame-based timing is not perfectly deterministic across different hardware. If tests become flaky, consider increasing wait margins or using a polling-based approach.
- The harness controller directly accesses `level._current_checkpoint_index` (a private-by-convention var). If the Level script is refactored, the controller will need updating.
