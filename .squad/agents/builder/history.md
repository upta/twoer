# Builder History

## Learnings

### Win/Lose Overlay Z-Order Fix (2026-05-13)

**Files Modified:**
- `src/game/level/level.tscn` — Replaced WinLabel + LoseLabel with ResultOverlay CanvasLayer (layer 10)
- `src/game/level/level.gd` — Updated references to use single result_overlay + result_label

**Bug Fixed:**
- Win/lose labels rendered in world space (Node2D children) so they appeared BEHIND the UI CanvasLayer. Text wasn't truly screen-centered either.

**Fix:**
- CanvasLayer at layer 10 guarantees rendering above all other UI (game UI is default layer 1)
- Full-rect anchored ColorRect (70% black) provides readable backdrop
- Full-rect Label with centered alignment ensures proper centering regardless of viewport size
- process_mode = PROCESS_MODE_ALWAYS keeps overlay visible when tree is paused
- Consolidated two labels into one — text set dynamically in `_trigger_win`/`_trigger_lose`

**Pattern:**
- For "always on top" UI overlays in Godot: use a dedicated CanvasLayer with high layer number + PROCESS_MODE_ALWAYS. Never put screen-space UI as direct children of a Node2D scene root.

### Dead Tower Bug + Attack Line Visuals (2026-05-12)

**Files Modified:**
- `src/game/entities/tower.gd` — Added hp guards and `_show_attack_line()` method

**Bug Fixed:**
- Dead towers could fire in the same frame after HP hits 0 but before `queue_free()` processes. Added `current_hp <= 0` guard in both `_process()` and `_fire_at_targets()`.

**Feature Added:**
- Visual attack indicators using Line2D children. On each fire, a line draws from tower to target using the tower's type color (semi-transparent). A tween fades it out over 0.15s then `queue_free`s the line node. AoE towers draw lines to ALL targets; single-target draws one.

**Patterns:**
- Tween-based ephemeral visuals: create child Line2D → tween modulate:a to 0 → callback queue_free. No timer nodes needed.
- Double-guard idiom: check death state in both the caller (`_process`) and the callee (`_fire_at_targets`) to handle any future call paths.

### Mana Actions Section — BATTLE_PLANNING UI Fix (2026-05-11)

**Files Modified:**
- `src/game/ui/planning_panel.gd` — Replaced `_revive_buttons` approach with `ManaActionsSection` container
- `src/game/ui/planning_panel.tscn` — Added `ManaActionsSection` VBoxContainer node
- `src/project.godot` — Added `revive_first_dead` and `heal_unit` input actions
- `src/validation/scripts/harness_controllers/level_harness_controller.gd` — Expose `heal_button_visible`

**Bug Fixed:**
- BATTLE_PLANNING showed NO mana spending options. The old revive section only rendered when `dead_units` was non-empty, and Heal was only on the (permanently hidden) TacticalPanel. Players had mana with nothing to do.

**Architecture:**
- `ManaActionsSection` is a dedicated VBoxContainer that's visibility-toggled by `_update_mode()` (visible only during BATTLE_PLANNING)
- Dynamic mana action nodes tracked in `_mana_action_nodes: Array[Control]` — rebuilt each update cycle
- Heal button always present (disabled if no alive units or insufficient mana)
- Revive buttons per dead unit type, with informative "No dead units" message when empty
- `_unhandled_input` handles `revive_first_dead` / `heal_unit` actions for validation scenarios

**Patterns:**
- Mana actions now live in their own section (not jammed into QueueList). Prevents `_update_queue_display()` from accidentally queue_free'ing mana UI nodes.
- Always show the section during BATTLE_PLANNING even when empty — player sees the mechanic exists.
- Harness controller introspects `_mana_action_nodes` array and categorizes by button text prefix ("Heal" vs "Revive").

### Phase Flow Bugfixes — Signal Ordering & UI Modes (2026-05-10)

**Files Modified:**
- `src/game/level/level.gd` — `call_deferred("begin_battle_planning")` in CHECKPOINT handler
- `src/game/systems/unit_deployer.gd` — `start_deployment()` gracefully handles empty queue
- `src/game/ui/planning_panel.gd` — Lane/reorder locked to BATTLE_PLANNING, Deploy button always enabled in mana mode

**Bugs Fixed:**
1. **Units never deploy after checkpoint** — Deploy button was disabled when queue was empty. In BATTLE_PLANNING, button must always be enabled (alive units keep fighting). Deployer also needs to gracefully no-op when queue is empty.
2. **First BATTLE_PLANNING redundant** — Lane selection and queue reorder were available in INITIAL_PLANNING (duplicating BATTLE_PLANNING). Per design.md, these belong exclusively in BATTLE_PLANNING. Moved by hiding LaneSection and reorder buttons during INITIAL_PLANNING.
3. **Planning UI invisible at checkpoint** — Signal ordering bug: `begin_battle_planning()` emitted BATTLE_PLANNING while CHECKPOINT handlers still pending. game_ui received BATTLE_PLANNING (visible=true) then remaining CHECKPOINT handler (visible=false). Fixed with `call_deferred`.

**Patterns:**
- **Signal ordering hazard:** Never emit a second signal from within a signal handler if other handlers haven't run yet. Use `call_deferred` for phase transitions triggered inside handlers.
- **UI mode gating:** Use `_is_mana_mode` flag + parent node `.visible` toggling to restrict sections by phase. `get_parent().get_parent()` navigates Button→HBox→Section.
- **Empty queue ≠ no battle:** Deployer and UI must handle empty queue gracefully during BATTLE_PLANNING — alive deployed units still fight.

### Squad Skills Symlinks (2026-05-10)

**Pattern:** Symlink `.squad/skills/<name>` → `../../submodules/agentic_godot_validation/.github/skills/<name>` using relative paths.

**Why:** Sub-agents spawned via `task` tool can't use the `skill` tool (platform limitation). By symlinking validation skill directories into `.squad/skills/`, sub-agents can read SKILL.md files directly via filesystem. The spawn template tells agents to check `.squad/skills/` for relevant skill docs before working.

**Follows existing pattern:** Project already symlinks `.github/skills/` and `tools/` from the submodule using relative paths.

### Checkpoint ANY-trigger Fix (2026-05-09)

**Files Modified:**
- `src/game/level/level.gd` — Changed checkpoint detection from ALL→ANY logic

**Bug Fixed:**
- Checkpoint required ALL alive units past the x-position. Units in harder lanes blocked the checkpoint for everyone. Changed to trigger when ANY alive unit reaches the checkpoint, matching design intent (fast scout triggers pause for replanning).

**Pattern:**
- ANY-trigger: flip from `all_past = true` / `< checkpoint_x` / `all_past = false` to `any_reached = false` / `>= checkpoint_x` / `any_reached = true`

### Phase 11: Checkpoint Visuals & Detection Fixes (2026-05-09)

**Files Modified:**
- `src/game/battlefield/lane.gd` — Added checkpoint marker lines and labels
- `src/game/level/level.gd` — Fixed alive_units filter, added checkpoint reached visuals
- `src/game/systems/unit_deployer.gd` — Handle _on_unit_reached_end (remove from deployed_units)

**Bugs Fixed:**
1. **Checkpoint detection counted dead/ended units** — `is_instance_valid()` alone passes for units that reached the end (state=DEAD, is_alive=false but not queue_free'd). Fixed by adding `unit.is_alive` check.
2. **Units that reached end stayed in deployed_units** — `_on_unit_reached_end` was `pass`. Now removes from array like `_on_unit_died` does.
3. **Lose condition counted dead-but-valid units** — Same is_alive fix applied to `_check_lose_condition()`.

**Patterns:**
- Checkpoint markers created programmatically in `_ready()` via Line2D + Label nodes
- `mark_checkpoint_reached()` method on Lane changes line/label color to green
- Level.gd calls `mark_checkpoint_reached()` on all 4 lanes before incrementing checkpoint index
- z_index = -1 keeps markers behind gameplay elements

### Phase 10: Phase Flow Restructure (2026-05-08)

**Correct Phase Flow (per Brian's design correction):**
1. INITIAL_PLANNING — spend GOLD (buy units, upgrades, pick lane, reorder queue) → click "Ready"
2. BATTLE_PLANNING — spend MANA (revive dead units, reorder queue, pick lane) → click "Deploy!"
3. BATTLE — units auto-deploy from queue, fight defenses. NO UI panels, NO mana actions.
4. CHECKPOINT — transient (instant): AI repairs/upgrades, +15 mana, immediately → BATTLE_PLANNING
5. Repeat 2→3→4 until WIN or LOSE.

**Key Design Corrections:**
- Tactical panel (redirect/hold/heal) does NOT exist during battle — all mana decisions at checkpoints
- Planning panel has two modes: gold mode (INITIAL) shows shop/upgrades; mana mode (BATTLE_PLANNING) shows revive + queue only
- CHECKPOINT is invisible to player — AI acts synchronously, then player sees BATTLE_PLANNING
- Dead units tracked in UnitRegistry.dead_units for revive candidates (30 mana, 50% HP)
- Lose condition: queue empty AND no alive deployed units (during BATTLE phase)

**Files Modified:**
- `src/game/core/unit_registry.gd` — Added dead_units array, record_death(), revive_unit(), REVIVE_COST/REVIVE_HP_PERCENT
- `src/game/systems/unit_deployer.gd` — _on_unit_died now calls registry.record_death()
- `src/game/level/level.gd` — CHECKPOINT instant transition, removed ai_action_complete handler
- `src/game/ui/game_ui.gd` — Tactical panel always hidden, phase-based planning visibility
- `src/game/ui/planning_panel.gd` — Gold/mana mode split, revive UI section, shop hidden in mana mode

**Patterns:**
- Use `get_parent()` to toggle entire scene tree sections (ShopSection visibility)
- Revive buttons generated dynamically from dead_units counts, refreshed on queue/mana changes
- Phase-based UI mode tracked with `_is_mana_mode` flag updated on every phase change

### Phase 9: Checkpoint Freeze & Queue Reorder Bugfixes (2026-05-08)

**Files Modified:**
- `src/game/level/level.gd` — Added battlefield.process_mode toggle in `_on_phase_changed()`
- `src/game/core/unit_registry.gd` — Added `move_unit_in_queue(from, to)` method
- `src/game/ui/planning_panel.gd` — Queue display now uses HBoxContainer with ▲/▼ buttons

**Key Patterns:**
- **Battlefield freeze via process_mode:** Setting `battlefield.process_mode = PROCESS_MODE_DISABLED` freezes ALL child nodes (units, towers) during non-BATTLE phases. UI stays responsive because it's in a separate CanvasLayer (not under Battlefield).
- **Pattern: Use process_mode for bulk pause, not per-unit state checks.** Much simpler than iterating units.
- Queue reorder uses remove_at + insert (not swap) to maintain relative order of other items.
- Button callbacks use `.bind(i, i-1)` / `.bind(i, i+1)` for up/down — indices captured at creation time.

**Decisions:**
- Battlefield disabled during ALL non-BATTLE phases (INITIAL_PLANNING, CHECKPOINT, BATTLE_PLANNING, LEVEL_COMPLETE) — not just CHECKPOINT
- Tactical panel visibility bug was a downstream symptom of Bug 1, not its own code issue

### Phase 8:Critical Bugfixes from Playtesting (2026-05-08)

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

