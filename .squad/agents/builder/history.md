# Builder History

## Learnings

### Phase 8: Critical Bugfixes from Playtesting (2026-05-08)

**Files Modified:**
- `src/game/level/level.gd` — Fixed signal argument mismatch, added checkpoint detection, fixed win/lose signal emission order
- `src/game/entities/unit.gd` — Fixed reached_end to stop unit processing after emission
- `src/game/main.gd` — Added CanvasLayer for UI to fix Control node layout issues

**Critical Bugs Fixed:**

1. **Signal argument mismatch (ERROR: Method expected 1 argument but called with 2)**
   - Root cause: Signals `reached_end` and `unit_died` already pass `self`, but `.bind(unit)` added duplicate argument
   - Fix: Removed `.bind(unit)` from signal connections in `_on_unit_deployed()`
   - Pattern: When signals explicitly pass the sender as first argument, don't bind it again

2. **Win/lose conditions never triggered**
   - Root cause: `game_manager.level_won.emit()` and `.level_lost.emit()` called AFTER `get_tree().paused = true`
   - Fix: Moved signal emissions BEFORE pausing the tree so they propagate to connected handlers (main.gd)
   - Pattern: **Always emit signals before pausing the scene tree** — paused state blocks signal propagation in some cases

3. **Checkpoint detection missing**
   - Root cause: No code checked unit positions against `checkpoint_positions` array
   - Fix: Added `_physics_process()` that checks if all alive deployed units have passed current checkpoint x-position
   - Trigger: `game_manager.phases.reach_checkpoint()` when all alive units past checkpoint
   - Pattern: Use `_current_checkpoint_index` to track progression through checkpoint array (reset to 0 in setup)

4. **Lose condition incorrectly checked deploying state**
   - Root cause: `not deployer.is_deploying` doesn't account for units still in queue
   - Fix: Check `game_manager.units.unit_queue.is_empty()` AND deployed_units count
   - Pattern: Lose only when both queue empty AND no alive deployed units

5. **Units continued moving after reaching end**
   - Root cause: `reached_end.emit()` fired but unit state remained MOVING, causing repeated signal emissions
   - Fix: Set `state = State.DEAD` and `is_alive = false` immediately after `reached_end.emit()`
   - Pattern: Terminal state transitions (win/lose) should set entity state to prevent further processing

6. **Level select UI layout broken**
   - Root cause: Control nodes (level_select.tscn) added as children of Node2D (main) don't respect anchors/layout_mode
   - Fix: Added CanvasLayer as `ui_layer` in main.gd, added level_select to ui_layer instead of directly to Node2D
   - Pattern: **UI Control nodes must be children of CanvasLayer when parent scene is Node2D** — only CanvasLayer/Control parents support layout properties

**Decisions:**
- Used `PhaseManager.Phase` enum properly throughout (removed direct phase assignment in favor of `complete_level()`)
- Checkpoint detection runs only during BATTLE phase to avoid false triggers
- Deployer already removes dead units from its array via `_on_unit_died`, so level.gd doesn't duplicate removal
- `_on_unit_died` parameter renamed to `_unit` since it's now unused (deployer handles tracking)

### Phase 7: Level Select + Main Integration (2026-05-08)

**Files Created:**
- `src/game/ui/level_select.gd` + `level_select.tscn` — Full-screen level select menu with title and 3 level buttons

**Files Modified:**
- `src/game/main.gd` — Added orchestration between level select and gameplay
- `src/game/level/level.gd` — Added signal emissions on win/lose

**Key Patterns:**
- Level select uses Control root with full-rect anchors and dark background
- VBoxContainer with centered alignment for layout (title → subtitle → spacer → buttons)
- Buttons sized at 300x60 minimum, large font (20pt) for readability
- Signal chain: level_select.level_selected → main._on_level_selected → instantiate level
- Win/lose flow: level emits game_manager.level_won/level_lost → main starts 2s timer → return to level select
- Main unpause tree via `get_tree().paused = false` when showing level select

**Decisions:**
- Used dynamic scene instantiation in main.gd rather than switching scene tree
- 2-second delay before returning to menu gives player time to read win/lose message
- Level select scene preloaded for instant display on return
- queue_free() used for cleanup rather than remove_child() to prevent memory leaks

### Phase 5 + 6: UI and Level Integration (2026-05-08)

**Files Created:**
- `src/game/ui/hud.gd` + `hud.tscn` — Top-bar HUD displaying gold, mana, phase, queue count, and current lane
- `src/game/ui/planning_panel.gd` + `planning_panel.tscn` — Shop, queue display, lane selector, start battle button
- `src/game/ui/tactical_panel.gd` + `tactical_panel.tscn` — Tactical actions (redirect, hold, heal) during battle phase
- `src/game/ui/game_ui.gd` + `game_ui.tscn` — CanvasLayer wrapper that manages all UI panels
- `src/game/level/level.gd` + `level.tscn` — Master level scene integrating all systems
- `src/game/level/level_data.gd` — Static level definitions (3 levels with varying defenses)

**Key Patterns:**
- UI panels show/hide based on PhaseManager.phase_changed signal
- Planning panel visible during INITIAL_PLANNING and BATTLE_PLANNING
- Tactical panel visible during BATTLE only
- Level.setup() uses call order: game_manager.setup_level() → battlefield.setup() → deployer.setup() → ai_defender.setup() → ui.setup()
- Win condition: Any unit reaches end (unit.reached_end signal)
- Lose condition: deployment_complete fires AND all deployed_units are dead
- Checkpoint flow: BATTLE → CHECKPOINT (pause, AI acts, +15 mana) → BATTLE_PLANNING → BATTLE
- Tactical actions spend mana: Redirect (20), Hold (15 on first press only), Heal (20)
- Heal finds first alive deployed unit and restores 30 HP

**Decisions:**
- Hold button changes text to "Release Hold" when active, doesn't cost mana to release
- Revive button disabled (units queue_free on death, can't revive yet)
- Lane selector buttons use toggle_mode for visual feedback
- Start battle button disabled when queue is empty to prevent empty deployment
- Used typed variables throughout (: EconomyManager, : Array[Button], etc.)

### Phase 1 Foundation (2025-05-07)
Created core game managers in `src/game/core/`:
- `economy_manager.gd`: EconomyManager (gold/mana tracking with signals)
- `unit_registry.gd`: UnitRegistry (unit queue, upgrades, stats lookup)
- `phase_manager.gd`: PhaseManager (state machine with phase validation)
- `game_manager.gd`: GameManager (orchestrator owning all three managers)

Patterns used:
- All managers extend Node for scene tree integration
- Typed variables throughout (`var gold: int`, `var economy: EconomyManager`)
- Signal-driven state changes for UI reactivity
- Public properties/methods exposed for harness controller observation
- Phase transitions validated to prevent illegal state changes
- Upgrade multipliers applied in `get_stats()` for clean stat lookup

Decision: Used `class_name` declarations so managers can be typed elsewhere (e.g., `var economy: EconomyManager`)

## Phase 2 — Entities Created (2026-05-07)

### Files Created
- `src/game/entities/unit.gd` + `unit.tscn` — CharacterBody2D with MOVING/ATTACKING/DEAD state machine
- `src/game/entities/tower.gd` + `tower.tscn` — StaticBody2D with range detection and FIFO/splash targeting
- `src/game/entities/wall.gd` + `wall.tscn` — StaticBody2D barrier with simple HP tracking

### Patterns Used

**Collision Layer Architecture:**
- Layer 1: Units (CharacterBody2D) — mask 2 (detect defenses)
- Layer 2: Defenses (StaticBody2D) — mask 1 (detect units)
- Area2D nodes use appropriate masks for detection zones

**Unit State Machine:**
- MOVING: `velocity = Vector2(speed, 0)`, `move_and_slide()`
- ATTACKING: `velocity = Vector2.ZERO`, timer-based damage application
- DEAD: no processing, entity queued for removal
- Attack detection via Area2D positioned 20px ahead (+x) with radius 20
- Signal connection to target's destroyed signal for state transition back to MOVING

**Tower Targeting:**
- FIFO for non-splash: `targets_in_range[0]` (first to enter)
- Splash: iterate all targets in range
- `body_entered` appends, `body_exited` removes from array
- Fire timer runs continuously, damage only applied when targets present
- Upgrade calculations at usage time: `base_damage * (1.0 + 0.25 * upgrade_level)`

**Scene Structure:**
- All entities use ColorRect placeholders with type-specific colors
- HealthBar (ProgressBar) positioned above each entity (-15 to -22 y-offset)
- Collision shapes sized per entity type (units: 16x16, towers: 28x28, walls: 40x28)
- Area2D for detection zones (attack/range) with separate collision shapes

**Harness Compatibility:**
- Every entity has `get_state() -> Dictionary` returning observable state
- All public properties typed and readable
- Signal emissions for lifecycle events (died, destroyed, upgraded)
- Groups used for entity type identification ("unit", "tower", "wall")

### Decisions Made
- Used Area2D for attack/range detection rather than raycasting (simpler, signal-driven)
- Health bars update in `take_damage()` for immediate visual feedback
- Units check x-position > 2000 for "reached end" (will connect to lane endpoints later)
- `is_instance_valid()` checks before applying damage prevent errors on queued entities
- Color constants defined per entity type for easy visual identification during testing

## Phase 3 — Battlefield (2026-05-08)

### Files Created
- `src/game/battlefield/lane.gd` + `lane.tscn` — Node2D container for one lane's units and defenses
- `src/game/battlefield/battlefield.gd` + `battlefield.tscn` — Root battlefield containing 4 lanes

### Patterns Used

**Lane Architecture:**
- Lane extends Node2D with exported `lane_index` and `lane_height` (120px default)
- Two child containers: DefenseContainer and UnitContainer (both Node2D)
- Checkpoint positions stored as Array[float] for later GameManager integration
- ColorRect background (1200x120) for visual lane boundaries
- Line2D nodes for top/bottom borders
- Lanes positioned vertically: y=80, y=200, y=320, y=440

**Battlefield Setup:**
- `setup(level_data)` parses lane/defense structure from Dictionary
- Defense spawning: instantiates tower/wall scenes, calls initialize(), positions via add_defense()
- Level data format: `{"lanes": [{"defenses": [{"type": "Wall", "x": 200}, ...]}]}`
- Preloaded PackedScenes for tower and wall to avoid runtime loading

**Container Pattern:**
- `add_unit(unit_node)` / `add_defense(defense_node, x_pos)` handle parenting and positioning
- `get_units()` / `get_defenses()` return typed Array[Node2D] filtering by validity
- `get_all_units()` / `get_all_defenses()` aggregate across all 4 lanes
- `clear()` safely removes all children using `is_instance_valid()` checks

**Harness Compatibility:**
- `get_state()` on Lane returns lane_index, unit_count, defense_count
- `get_state()` on Battlefield returns aggregated state plus per-lane breakdown

### Decisions Made
- Fixed unit.gd reached_end threshold from 2000 to 1150 (matches ~1200px lane width)
- Lanes store checkpoint positions but don't enforce them (GameManager will handle checkpoint logic)
- Defense spawning uses type string matching ("Wall", "AoE", "RapidFire", "Sniper")
- Units added at center of lane height via `lane.lane_height / 2.0` calculation

## Phase 4 — Game Systems (2026-05-08)

### Files Created
- `src/game/systems/unit_deployer.gd` — Automated unit deployment with timer-based spawning
- `src/game/systems/ai_defender.gd` — AI logic for between-wave defense upgrades/repairs

### Patterns Used

**UnitDeployer:**
- Timer-based deployment: `deploy_interval = 3.0` seconds between units
- State flags: `is_deploying`, `is_held` control timer behavior
- `deployed_units` Array[Node2D] tracks all spawned units for win/lose checks
- Signal connections: `unit_died` removes from tracking array, `reached_end` for win detection
- Positioning: units spawn at x=50, y=lane center
- `_deploy_next_unit()` pops from queue, gets stats, instantiates, positions, connects signals
- Emits `unit_deployed` per unit, `deployment_complete` when queue empty

**AIDefender:**
- `execute_between_waves()` runs synchronously (no async/timer logic)
- Step 1: Repair all walls (iterate defenses, call repair() on wall group members)
- Step 2: Find tower with highest `total_damage_dealt`
- Step 3: Upgrade that tower if upgrade_level < 2
- `last_actions` Array[String] logs what AI did for debugging/harness observation
- Emits `ai_action_complete` when done

**System Initialization:**
- Both systems use `setup()` to receive dependencies (UnitRegistry, Battlefield)
- UnitDeployer preloads unit.tscn as PackedScene
- Deployer modifies UnitRegistry.unit_queue directly via remove_at(0)

### Decisions Made
- Deployer handles queue modification (removes deployed units from queue) to keep registry state accurate
- AI upgrade logic is simple greedy (highest damage dealer) — can be refined later
- Hold/release mechanism pauses timer but doesn't reset it (allows precise grouping)
- Lane redirect changes `current_lane` immediately (affects next deploy, not already-deployed units)
- Deployer stops itself (`is_deploying = false`) when queue empty

