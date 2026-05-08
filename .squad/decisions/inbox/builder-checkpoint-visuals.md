### 2026-05-09: Checkpoint Visual Markers & Detection Fix

**By:** Builder (Core Dev)

**What:** Added visual checkpoint indicators and fixed three bugs in checkpoint/lose detection.

**Visuals:** Translucent yellow Line2D at x=400 and x=800 in each lane with "CP1"/"CP2" labels. Lines turn green when checkpoint is reached. Drawn programmatically in lane.gd `_ready()`, not in .tscn.

**Bugs Fixed:**
- Alive unit checks now require `is_instance_valid(unit) AND unit.is_alive` (previously only checked validity)
- Units reaching the end are now removed from `deployed_units` array (was a no-op `pass`)
- Both checkpoint detection and lose condition use the same corrected filter

**Why:** Units that reached the end (x>1150) set state=DEAD and is_alive=false but never queue_free(), so they passed is_instance_valid() and polluted position-based calculations. This caused checkpoint triggers to behave unpredictably.
