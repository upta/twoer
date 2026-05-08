# Lead — Agent History

*Game Architect for Twoer*

---

## Learnings

### 2025-01-22: Initial Architecture for Twoer Prototype

**Context:** Decomposed DESIGN.md into a complete architecture plan for the reverse tower defense game "Twoer."

**Key Architecture Patterns:**

1. **Phase-Driven State Machine**
   - PhaseManager (child of GameManager) controls game flow: INITIAL_PLANNING → BATTLE_PLANNING → BATTLE → CHECKPOINT → ...
   - UI panels show/hide based on current phase
   - No singletons — state lives in Level scene, resets between levels
   - **File:** `src/game/core/phase_manager.gd`

2. **Queue-Based Unit Deployment**
   - UnitRegistry owns array of unit type strings: `["Tank", "Swarm", "Swarm"]`
   - UnitDeployer instantiates units on timer from queue data
   - Units only exist when deployed (not pre-instantiated)
   - **Files:** `src/game/core/unit_registry.gd`, `src/game/systems/unit_deployer.gd`

3. **Lane-Centric Spatial Model**
   - 4 lanes, each a Node2D with DefenseContainer + UnitContainer children
   - Units don't switch lanes mid-battle (lane redirect only affects undeployed units)
   - Tower range extends to neighboring lanes via Area2D radius
   - **Files:** `src/game/battlefield/lane.gd`, `src/game/battlefield/battlefield.gd`

4. **Signal-Heavy, Low-Coupling Architecture**
   - EconomyManager emits `gold_changed`, `mana_changed`
   - UnitRegistry emits `queue_changed`, `upgrade_purchased`
   - Units emit `unit_died`, `reached_end`
   - Towers emit `tower_destroyed`, `damage_dealt`
   - PhaseManager emits `phase_changed`
   - UI subscribes to signals, doesn't poll state

5. **Combat via Area2D Overlap**
   - Units use CharacterBody2D, move right until collision
   - Towers/Walls use StaticBody2D with Area2D for range detection
   - On overlap: unit enters ATTACKING state, applies damage on timer
   - AoE towers damage all overlapping units, not just first
   - **Files:** `src/game/entities/unit.gd`, `src/game/entities/tower.gd`

6. **Per-Level Economy Reset**
   - Gold: fresh budget per level (defined in level data), no carryover
   - Mana: resets per battle segment, +15 per checkpoint reached
   - **File:** `src/game/core/economy_manager.gd`

**Key File Paths:**
- `src/game/core/` — GameManager, EconomyManager, PhaseManager, UnitRegistry
- `src/game/entities/` — unit.tscn, tower.tscn, wall.tscn
- `src/game/battlefield/` — battlefield.tscn, lane.tscn
- `src/game/systems/` — unit_deployer.gd, ai_defender.gd
- `src/game/ui/` — hud.tscn, planning_panel.tscn, tactical_panel.tscn, level_select.tscn
- `src/game/level/` — level.tscn, level_data.gd

**Build Order Strategy:**
- Phase 1: Core data structures (EconomyManager, UnitRegistry, PhaseManager, GameManager)
- Phase 2: Entities (Unit, Tower, Wall — can be built in parallel)
- Phase 3: Battlefield (Lane, Battlefield — needs entities to reference)
- Phase 4: Game systems (UnitDeployer, AIDefender — needs entities + battlefield)
- Phase 5: UI (HUD, PlanningPanel, TacticalPanel — needs core systems)
- Phase 6: Level integration (Level scene assembles everything)
- Phase 7: Meta UI (Level Select)
- Phase 8: Polish (tooltips, visual feedback)

**Delegation Notes:**
- Builder should start with Phase 1 (F1-F3): EconomyManager, UnitRegistry, PhaseManager, GameManager shell
- Validator will need harnesses for:
  - Unit deployment flow (queue → deploy → movement → combat)
  - Phase transitions (planning → battle → checkpoint)
  - Economy validation (gold spending, mana recovery)
  - Win/lose conditions (unit reached end, all units dead)

**Design Constraints to Enforce:**
- No singletons (state tied to Level scene lifecycle)
- Typed GDScript variables (`var gold: int`, not `var gold`)
- Signals over direct references (loose coupling)
- Shallow scene trees (prefer composition over deep nesting)
- No /tmp writes (validation outputs go to repo-relative paths)

---

### 2025-07-15: Enriched Validation Skill Files for Sub-Agent Consumption

**Context:** Sub-agents spawned via `task` tool can't use the `skill` tool — they read SKILL.md files directly from `.squad/skills/` symlinks. The original files were ~29 lines and lacked schema details, step op signatures, comparator lists, and examples.

**What was enriched:**

1. **author-validation-scenario/SKILL.md** (29→81 lines): Added scenario JSON schema table, step operations reference with shapes, comparator list, pipeline details (sources/ops/assert), harness controller pattern with `get_observed_state()` return shape, and compact assert_value + assert_pipeline examples from the move_up_smoke reference scenario.

2. **debug-validation-failure/SKILL.md** (30→67 lines): Added artifact file locations and shortcut paths, summary.json reading guide (failed_assertion fields, verification shapes), event_log.json structure, scene_tree.json structure, signal facts shape (count/connected/signal_name/source_path/last_emitted_msec), and common failure pattern diagnostic table.

3. **install-agentic-godot-validation/SKILL.md** (27→38 lines): Added Step 8 for Squad skill symlinks with PowerShell commands to create junctions from `.squad/skills/` → submodule skill directories, plus a check that symlinks resolve.

**Source docs used:** `plans/specs/scenario_format.md`, `plans/specs/artifact_schema.md`, `docs/write-a-harness.md`, `docs/write-a-scenario.md`, `examples/minimal_poc/validation/scenarios/move_up_smoke.json`.

---

*End of History*
