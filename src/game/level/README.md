# Twoer UI & Level System

## Phase 5: UI Components

### HUD (`src/game/ui/hud.gd`)
Top-bar display showing:
- Gold amount
- Mana amount
- Current phase
- Queue size
- Current deployment lane

Auto-updates via signals from game systems.

### Planning Panel (`src/game/ui/planning_panel.gd`)
Shown during INITIAL_PLANNING and BATTLE_PLANNING phases.

**Features:**
- Unit shop with Buy buttons (Swarm 10g, Tank 40g, Speeder 25g)
- Upgrade buttons showing current level (max level 3)
- Queue display (numbered list of queued units)
- Lane selector (4 toggle buttons)
- Start Battle button (changes text based on phase, disabled if queue empty)

### Tactical Panel (`src/game/ui/tactical_panel.gd`)
Shown during BATTLE phase only.

**Actions:**
- **Redirect Lane (20m)**: Cycles deploy lane (0→1→2→3→0)
- **Hold (15m)**: Pauses deployment (toggle, changes to "Release Hold")
- **Heal (20m)**: Heals first alive deployed unit for 30 HP
- **Revive (30m)**: Disabled (coming soon)

All buttons disable when insufficient mana.

### Game UI (`src/game/ui/game_ui.gd`)
CanvasLayer container that manages all UI panels. Handles show/hide logic based on phase transitions.

## Phase 6: Level Integration

### Level Scene (`src/game/level/level.gd`)
Master scene assembling all game systems.

**Setup Flow:**
1. `game_manager.setup_level(level_data)` — configures economy, units, phases
2. `battlefield.setup(level_data)` — spawns defenses
3. `deployer.setup(units, battlefield)` — connects deployer to registry and battlefield
4. `ai_defender.setup(battlefield)` — connects AI to battlefield
5. `ui.setup(game_manager, deployer)` — connects UI to game state
6. `economy.reset_mana(50)` — sets starting mana
7. `phases.start_level()` — begins INITIAL_PLANNING phase

**Win Condition:**
Any deployed unit reaches the end (x > 1150) → Victory

**Lose Condition:**
Deployment complete AND all deployed units dead → Defeat

**Checkpoint Flow:**
1. Units reach checkpoint position → CHECKPOINT phase
2. Deployer pauses
3. AI executes between-wave actions (repair walls, upgrade towers)
4. +15 mana granted
5. Return to BATTLE_PLANNING

### Level Data (`src/game/level/level_data.gd`)
Static level definitions:
- **Level 1 (Tutorial)**: 150g, minimal defenses (1 wall, 1 tower)
- **Level 2 (Mixed Defenses)**: 200g, varied defense placement
- **Level 3 (Fortress)**: 250g, heavy fortifications across all lanes

**Format:**
```gdscript
{
    "name": "Level Name",
    "starting_gold": 150,
    "lanes": [
        { "defenses": [{"type": "Wall", "x": 400}, ...] },
        ...
    ]
}
```

## Usage

The main.gd loads level 1 automatically:
```gdscript
var level: Level = level_scene.instantiate()
add_child(level)
level.setup(LevelData.get_level(1))
```

To load a different level, change the number in `LevelData.get_level(N)`.

## Game Loop

1. **INITIAL_PLANNING**: Player buys units, upgrades, picks lane
2. **BATTLE_PLANNING**: Player reviews queue, adjusts lane → clicks "Deploy!"
3. **BATTLE**: Units deploy every 3 seconds, tactical actions available
4. **CHECKPOINT**: Units pause at checkpoint, AI acts, +15 mana
5. **BATTLE_PLANNING**: Repeat from step 2
6. **LEVEL_COMPLETE**: Win (unit reached end) or Lose (all units dead)
