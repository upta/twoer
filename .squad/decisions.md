# Decisions

Team decisions log. Append-only.

---

### 2026-05-08: Architecture Plan — Phase Breakdown & Dependencies

**By:** Lead (Game Architect)

**What:** Decomposed DESIGN.md into 8 dependency-ordered build phases and 10 architectural decisions.

**Key Phases:**
1. Foundation (core managers: economy, units, phases, game state)
2. Entities (unit, tower, wall scenes)
3. Battlefield (lanes, spatial structure)
4. Game Systems (deployer, AI)
5. UI (HUD, panels, tacticals)
6. Level Integration
7. Meta UI (level select)
8. Polish (optional)

**Key Architecture Decisions:**
1. **Lane Structure**: Node2D containers (not grid-based). Keeps spatial locality, enables cross-lane queries.
2. **Phase State Machine**: Child of GameManager, not singleton. State lifetime tied to Level, easier reset.
3. **Unit Queue**: Flat string arrays (not instances). Queue editing simple, stats lookup at deploy time.
4. **Economy Scope**: Per-level gold, per-battle mana (+15 per checkpoint). No carryover between levels.
5. **Combat System**: Area2D overlap, not pathfinding. Simple, fast, works for lanes.
6. **AI Heuristic**: Repair all walls, upgrade tower with highest damage dealt. Deterministic, predictable.
7. **Win/Lose Conditions**: Polling unit states. Simple, no race conditions.
8. **File Organization**: `core/` (managers) → `entities/` → `battlefield/` → `systems/` → `ui/` → `level/`.
9. **Deployment Timer**: Timer node with pause/resume (Hold action stops timer).
10. **Level Data**: Hardcoded GDScript dicts (3 levels). Fast to prototype.

**Why:** Clear dependencies enable parallel work. All decisions include rationale and implications.

---

### 2026-05-08: Phase 1 Foundation Implementation

**By:** Builder (Implementation Engineer)

**What:** Implemented 4 core manager scripts (Phase 1 Foundation):
- `src/game/core/economy_manager.gd` — gold/mana tracking, signals
- `src/game/core/unit_registry.gd` — unit queue, upgrades, stats lookup
- `src/game/core/phase_manager.gd` — state machine, transitions
- `src/game/core/game_manager.gd` — orchestrator shell

**Why:**
- Node-based managers integrate with scene lifecycle and signals
- Typed variables (`class_name`) enable autocomplete and type safety
- All state exposed via properties + signals (harness-compatible)
- Phase transitions validated; upgrade stats on-demand calculation
- Ready for Phase 2 (Entities) and integration into Level scene

**Status:** Complete. Ready for Phase 2 build.

---

### 2026-05-08: User Directive — Validation with Development

**By:** Brian (via Copilot)

**What:** Validation testing should happen alongside building, not after. Human players do playtesting — validation scenarios verify mechanics work, they don't replace human QA.

**Why:** User request — captured for team memory

---

### 2026-05-08: Phase 2 — Collision Layer Architecture & Entity Design

**By:** Builder (Implementation Engineer)

**What:** Phase 2 delivered 6 entity scripts with collision layers, attack detection, and upgrade mechanics:
- **Collision Layers:** Layer 1 (units) / Layer 2 (defenses) with proper masks for separation
- **Unit Detection:** Area2D positioned ahead of unit for attack range discovery
- **Tower Targeting:** FIFO array (first-in, first-out order for non-splash)
- **Upgrade Calculation:** Dynamic damage/range boost computed at usage time
- **Entity Lifecycle:** Signals (unit_died, tower_destroyed, wall_destroyed) with queue_free()
- **Visual Placeholder:** ColorRect nodes with type-specific colors and sizes

**Why:**
- Layer separation prevents unwanted collisions while enabling physics-based interactions
- Positioned Area2D is more performant than raycasting for attack range
- FIFO targeting matches design spec and is simple to implement
- Dynamic upgrades keep base stats immutable, simplifying state tracking
- Signal-based lifecycle integrates cleanly with scene architecture

**Status:** Complete. Entities ready for Battlefield integration (Phase 3).

---

### 2026-05-08: Phase 3-4 — Battlefield Structure & Game Systems

**By:** Builder (Implementation Engineer)

**What:** Phase 3-4 delivered battlefield orchestration and game systems:
- **Lane Structure:** Dual containers (DefenseContainer, UnitContainer) for clean separation
- **Checkpoint Tracking:** Lane stores positions, GameManager queries cross-lane for batch detection
- **Unit Deployment:** Timer-based queue modification with pause/resume control (no reset on hold)
- **AI Heuristic:** Greedy upgrade of tower with highest total_damage_dealt (deterministic, predictable)
- **Win/Lose Conditions:** Win = any unit reaches 1150px, Lose = all units dead + deployment complete

**Why:**
- Dual containers prevent z-index conflicts and simplify querying
- Checkpoint threshold at 1150px gives 50px buffer from edge
- Deployer modifies registry queue to keep state accurate for UI
- Greedy AI heuristic rewards towers doing actual damage, simple enough for prototype
- Win/lose logic avoids false triggers during active battle

**Status:** Complete. Systems integrated into Level scene (Phase 5-6).

---

### 2026-05-08: Phase 5-6 — UI & Level Integration

**By:** Builder (Implementation Engineer)

**What:** Phase 5-6 delivered complete UI and level integration:
- **Phase-Based UI:** PlanningPanel (INITIAL_PLANNING/BATTLE_PLANNING), TacticalPanel (BATTLE)
- **Hold Button:** Costs 15 mana on first press, free on release
- **Win/Lose Detection:** Win = unit reaches end, Lose = all units dead + deployment complete
- **Heal Targeting:** First alive deployed unit for 30 HP
- **Revive Placeholder:** Disabled with "Coming soon" (requires death mechanics refactor)
- **Level System:** 3 hardcoded levels with increasing difficulty
- **Full Integration:** Level orchestrator wires GameManager, Battlefield, UI, and phase progression

**Why:**
- Phase-based visibility keeps UI automatically synchronized with game state
- Hold button cost is tactical (commit mana to delay) vs operational (cost both ways)
- Win/lose conditions avoid false positives during active battle
- Heal targeting is simple and deterministic (can manipulate via deployment timing)
- Revive disabled pending refactor of death mechanics (currently queue_free())
- 3 levels provide playtest content with escalating challenge

**Status:** Complete. Full game loop playable.

---
