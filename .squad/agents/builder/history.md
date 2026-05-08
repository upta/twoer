# Builder History

## Learnings

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
