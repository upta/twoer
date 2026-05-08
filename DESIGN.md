# Twoer

> A reverse tower defense where you play as the attackers — spending limited resources to buy and deploy distinct unit types that counter pre-placed defenses. Each level is a resource-management puzzle: read the defenses, pick the right unit composition, and overwhelm them.

## Core Fantasy

The puzzle-like tension of resource management — "I have limited gold, the defenses are right there, and if I pick the wrong composition, I'm wasted." Every level is a solvable puzzle if you read it right.

## Reference Points

- **Dungeon Keeper** — the fantasy of playing as the villain, commanding the "bad guys"
- **Plants vs Zombies** — the sun/resource economy and the way each level becomes a unique puzzle because of the distinct roles of each unit type

## Core Loop

The player **evaluates** defenses and **spends** gold to build a unit composition, then **deploys** them autonomously across waves — spending mana on tactical adjustments — to **overwhelm** the defenses. Winning progresses through an increasingly challenging campaign.

### Flow Per Level

1. **Initial Planning Phase** — Player sees all defenses (full visibility). Spends gold to buy and upgrade units.
2. **Battle Planning Phase** — Player sets queue order, picks starting lane, spends mana on tactical actions.
3. **Battle** — Units deploy one at a time on a fixed timer, march down chosen lane autonomously.
4. **Checkpoint Reached** — Battle pauses. Deployed units freeze in place. Player enters another Battle Planning Phase (heal, revive, reorder undeployed queue).
5. **Repeat** — 2 checkpoints per level = 3 battle segments, 3 battle planning phases total.
6. **Win or Lose** — Win if any unit reaches the end. Lose if all units are destroyed.

### Player Actions

| Action | Phase | Input Cost | Effect |
|--------|-------|------------|--------|
| Buy Unit | Initial Planning | Gold (varies) | Add unit(s) to available pool |
| Upgrade Unit Type | Initial Planning | Gold (varies) | +stats to all units of that type |
| Set Queue Order | Battle Planning | Free | Arrange undeployed units in deploy order |
| Select Lane | Battle Planning | Free | Choose which lane next units deploy on |
| Lane Redirect | Battle (tactical) | 20 mana | Change deploy lane for future undeployed units |
| Hold | Battle (tactical) | 15 mana | Pause deployment to group up units |
| Heal | Battle Planning | 20 mana | Restore HP to one alive unit on the field |
| Revive | Battle Planning | 30 mana | Return one dead unit to queue at partial HP |
| Hover Tower | Initial Planning | Free | Tooltip showing tower type, damage, range |

### Rules & Numbers

#### Units

| Unit | Gold Cost | HP | Speed | Damage | Deploy Count | Notes |
|------|-----------|-----|-------|--------|--------------|-------|
| Swarm | 10 | 20 | Medium | 5 | 3 (pack) | Overwhelms single-target towers, dies to AoE |
| Tank | 40 | 150 | Slow | 15 | 1 | Soaks burst damage, struggles vs sustained DPS |
| Speeder | 25 | 40 | Fast | 8 | 1 | Outruns slow-firing towers, dies to rapid-fire |

- **Upgrades:** 2 levels per unit type, applies to all units of that type (stat boost)
- **Upgrade cost:** Roughly matches unit base cost per level, increasing per tier
- **Units can overlap** — no collision between friendly units; they pile up to attack obstacles together
- **Deployed units stay on their lane** — lane redirect only affects undeployed units
- **Minimum 1 unit required** to start a battle

#### Defenses (AI-Controlled)

| Defense | HP | Damage | Fire Rate | Range | Notes |
|---------|-----|--------|-----------|-------|-------|
| AoE Tower | Medium | Medium | Slow | Radius hits lane + neighbors | Splash damage, kills swarms, weak vs single targets |
| Rapid-Fire Tower | Low | Low per-hit | Fast | Lane + neighbors | Shreds speeders, low DPS vs high-HP tanks |
| Sniper Tower | Medium | High | Very Slow | Lane + neighbors | Burst single-target, kills tanks, overwhelmed by numbers |
| Wall | High | 0 | N/A | N/A | Blocks path, no damage, buys towers time |

- **All towers are placed inside lanes** and block unit movement (walls that shoot back)
- **Tower range radius** extends into neighboring lanes (a tower in lane 2 can hit lanes 1-3)
- **Units stop at towers/walls** and attack them to progress (same damage stat for both)
- **Tower targeting:** First-in, first-out (arrival order) — tanks absorb hits for units behind them
- **AoE exception:** Hits all units in the pile regardless of arrival order

#### AI Defender (Between Waves)

- Can **repair walls** (restore to full HP)
- Can **upgrade towers** (+25% damage/range per upgrade, max 2 upgrades per tower)
- Cannot build new towers or walls
- Heuristic: upgrades tower that dealt most damage or best counters player's most-used unit type

#### Economy

| Resource | Scope | Starting Amount | Earned By |
|----------|-------|-----------------|-----------|
| Gold | Per-level (fresh each level) | ~150 (tuned per level) | Level budget only, no carryover |
| Mana | Per-battle | 50 | +15 per checkpoint reached |

- No gold or unit carryover between levels — each level is a self-contained puzzle

### Win / Lose

- **Win:** At least 1 unit reaches the end of any lane
- **Lose:** All units are destroyed before any reach the end

### Difficulty

- **Level 1 (Tutorial):** Fewer towers, mostly one type — teaches the counter system
- **Level 2 (Mixed):** Mixed defense compositions — forces real composition choices
- **Level 3 (Hard):** Dense defenses, walls + mixed towers, AI upgrades aggressively between waves

## Prototype Scope

### In

- 4-lane top-down battlefield
- 3 unit types (Swarm, Tank, Speeder) with 2 upgrade levels each
- 4 defense types (AoE, Rapid-Fire, Sniper, Wall) controlled by AI
- Gold + mana dual economy
- 4 tactical/planning actions (lane redirect, hold, heal, revive)
- Planning → Battle → Checkpoint pause flow (2 checkpoints per level)
- AI defender repairs/upgrades between waves
- 3 pre-designed levels (tutorial, mixed, hard)
- Simple level select screen
- Basic HUD (gold, mana, unit queue, current lane indicator)
- Tower tooltips on hover during planning phase
- Colored shape placeholder art

### Out (explicitly deferred)

- Multiplayer (human vs human)
- Save/load system
- Sound/music
- Story/narrative
- Main menu beyond level select
- Settings screen
- Fog of war / imperfect knowledge
- More than 3 unit types
- Unit special abilities
- Campaign map / territory progression
- Gold/unit carryover between levels
- Branching upgrade paths

### Art Direction

Top-down view with colored geometric shapes. Units distinguished by shape and color:
- Swarm: small circles (e.g., green)
- Tank: large squares (e.g., blue)
- Speeder: triangles (e.g., yellow)
- Towers: distinct colored shapes per type
- Walls: rectangles
- Lanes: parallel horizontal strips with clear boundaries

No art pipeline — fully agent-buildable with primitive shapes.

### Target Session

10-20 minutes to play through all 3 levels.

## Open Questions & Risks

- **Number balancing:** All unit/tower stats are starting proposals. Mono-strategies (e.g., all-tanks) may be viable if damage numbers aren't tuned correctly. Requires playtesting.
- **Checkpoint pacing:** 2 checkpoints per level is a starting point. May need adjustment based on how long battle segments feel in practice.
- **AI upgrade heuristics:** Simple "upgrade most effective tower" may feel unfair or predictable. Needs playtesting to tune.
- **Revive balance:** Bringing dead units back at partial HP for 30 mana may be too strong or too weak depending on how much partial HP is. Exact revive HP% TBD.
- **Hold action feel:** Pausing the deploy timer is mechanically simple but may feel unclear to the player. May need visual feedback iteration.
- **Tower HP values:** Not yet defined — need to be balanced against unit damage to ensure fights at towers/walls last a meaningful but not tedious amount of time.
