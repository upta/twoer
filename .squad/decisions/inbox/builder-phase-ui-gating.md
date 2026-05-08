### 2026-05-10: Lane/Queue Actions Restricted to BATTLE_PLANNING Only

**By:** Builder (Core Dev)

**What:** Lane selection and queue reordering are now exclusively BATTLE_PLANNING actions. During INITIAL_PLANNING, only gold spending (buy/upgrade) is available. This matches design.md's action table.

**Why:** Brian reported the first BATTLE_PLANNING felt redundant. Root cause: INITIAL_PLANNING already offered lane/queue actions, making BATTLE_PLANNING purposeless. By restricting those actions to BATTLE_PLANNING, the first pause becomes meaningful — that's when you set your formation before battle starts.

**Implications:**
- Default lane is 0 (top) until player picks during first BATTLE_PLANNING
- Queue order during INITIAL_PLANNING is purchase order (FIFO)
- All tactical decisions (lane, order, revive, heal) happen at BATTLE_PLANNING checkpoints
