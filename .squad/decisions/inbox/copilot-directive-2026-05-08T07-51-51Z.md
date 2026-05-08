### 2026-05-08T07:51:51Z: User directive — Phase flow correction
**By:** Brian (via Copilot)
**What:** The correct game phase flow is:
1. INITIAL_PLANNING — spend GOLD on units and upgrades
2. BATTLE_PLANNING — spend MANA, reorder the unit queue. Queue only contains units that never deployed + resurrected units.
3. BATTLE — units move and fight
4. CHECKPOINT → return to BATTLE_PLANNING, repeat until all dead or someone reaches end

Key implications:
- Gold economy is INITIAL only. Mana economy is BATTLE_PLANNING only.
- No real-time tactical actions during BATTLE. All mana spending happens at checkpoints.
- Queue during BATTLE_PLANNING shows only undeployed + revived units.
- CHECKPOINT is just a transition back to BATTLE_PLANNING (not a separate visible phase).
**Why:** Design clarification — previous implementation mixed up when gold/mana are spent and showed tactical panel during battle incorrectly.
