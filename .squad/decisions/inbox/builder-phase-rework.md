### 2026-05-08: Phase Flow Restructure — Design Correction

**By:** Builder (Core Developer), requested by Brian

**What:** Corrected the game phase flow to match Brian's intended design. Removed real-time tactical actions during battle. Made CHECKPOINT a transient state.

**Corrected Flow:**
1. INITIAL_PLANNING (gold economy) → "Ready" button
2. BATTLE_PLANNING (mana economy: revive, reorder, lane pick) → "Deploy!" button
3. BATTLE (auto-deploy, pure combat, no UI panels)
4. CHECKPOINT (instant: AI repairs + upgrades, +15 mana) → automatically → BATTLE_PLANNING
5. Repeat 2-4 until WIN/LOSE

**What Was Wrong Before:**
- Tactical panel showed during BATTLE with redirect/hold/heal actions (wrong — all mana decisions happen at BATTLE_PLANNING checkpoints)
- Planning panel didn't distinguish gold vs mana economies
- No revive mechanic implemented
- CHECKPOINT was visible and waited for ai_action_complete signal

**Key Changes:**
- Tactical panel permanently hidden (can be deleted later)
- Planning panel has gold mode (INITIAL: shop + upgrades) and mana mode (BATTLE_PLANNING: revive + queue)
- Dead units tracked for revive (30 mana cost, 50% HP)
- CHECKPOINT transitions synchronously: AI → +15 mana → BATTLE_PLANNING

**Why:** Brian's design has all player decisions happening at planning checkpoints, not during real-time combat. Battle is pure spectacle + deployment timing.
