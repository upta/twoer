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
