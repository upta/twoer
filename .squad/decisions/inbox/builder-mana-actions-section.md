### Mana Actions Section — Dedicated UI Container

**By:** Builder

**What:** Moved all mana-spending UI (Heal + Revive) into a dedicated `ManaActionsSection` VBoxContainer in the planning panel, separate from the queue display. The section is always visible during BATTLE_PLANNING and hidden during INITIAL_PLANNING.

**Why:** The old approach injected revive buttons into `QueueList` which was also cleared by `_update_queue_display()`. Separating mana actions into their own container prevents cross-contamination and makes the feature discoverable even when no units have died yet.

**Implications:**
- Heal is now a BATTLE_PLANNING action (per design.md) accessible via button, not just TacticalPanel
- TacticalPanel remains hidden (its heal/revive are superseded by planning panel actions)
- Validation scenarios can use `revive_first_dead` and `heal_unit` input actions
- Harness controller exposes `heal_button_visible` metric
