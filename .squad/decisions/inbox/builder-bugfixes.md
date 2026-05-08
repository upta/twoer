# Decision: Critical Bugfix Patterns from Twoer Playtest

**Date:** 2026-05-08  
**Context:** Brian playtested Twoer and discovered 9 critical bugs causing runtime errors, broken win/lose conditions, and UI layout issues.

---

## Decisions Made

### 1. Signal Emission Order Matters with Tree Pausing

**Problem:** `game_manager.level_won.emit()` called after `get_tree().paused = true` prevented main.gd from receiving the signal.

**Decision:** **Always emit signals BEFORE pausing the scene tree.**

**Rationale:**
- Paused tree state can block signal propagation in certain scenarios
- Handlers like timers with `PROCESS_MODE_ALWAYS` need signals to arrive while tree is unpaused
- Signal ordering: complete phase → emit signal → pause tree

**Pattern:**
```gdscript
func _trigger_win() -> void:
    game_manager.phases.complete_level()
    deployer.pause_deployment()
    win_label.visible = true
    game_manager.level_won.emit()  # BEFORE pause
    get_tree().paused = true
```

---

### 2. Don't Double-Bind Signal Arguments

**Problem:** Signals `reached_end(unit: Node2D)` and `unit_died(unit: Node2D)` already pass `self`, but `.bind(unit)` added a second argument, causing "Method expected 1 argument but called with 2" errors.

**Decision:** **Remove `.bind()` when signal already passes the required parameter.**

**Rationale:**
- Signal definitions like `signal unit_died(unit: Node2D)` explicitly pass the sender
- Using `.bind(unit)` creates duplicate argument: handler receives `(unit_from_signal, unit_from_bind)`
- Only use `.bind()` when adding NEW context not already in signal signature

**Pattern:**
```gdscript
# WRONG:
unit.reached_end.connect(_on_unit_reached_end.bind(unit))  # Duplicates argument

# RIGHT:
unit.reached_end.connect(_on_unit_reached_end)  # Signal already passes unit
```

---

### 3. Control Nodes Require CanvasLayer Parent When Scene Root is Node2D

**Problem:** Level select UI (Control node with full-rect anchors) added as child of Node2D (main scene) rendered with broken layout.

**Decision:** **Add CanvasLayer as intermediary when mixing Node2D scenes with Control-based UI.**

**Rationale:**
- Control nodes use layout_mode/anchors which only work under CanvasLayer or Control parents
- Node2D doesn't support layout properties — treats Control as a regular Node2D child
- CanvasLayer provides proper viewport-relative positioning for UI

**Implementation:**
```gdscript
var ui_layer: CanvasLayer

func _ready() -> void:
    ui_layer = CanvasLayer.new()
    ui_layer.name = "UILayer"
    add_child(ui_layer)

func _show_level_select() -> void:
    current_level_select = level_select_scene.instantiate()
    ui_layer.add_child(current_level_select)  # Not add_child(current_level_select)
```

---

### 4. Terminal State Transitions Should Prevent Further Processing

**Problem:** Unit reached end and emitted `reached_end`, but continued moving and firing signal repeatedly.

**Decision:** **Set entity to terminal state (DEAD) immediately after terminal events (win/lose/complete).**

**Rationale:**
- Terminal events like "reached end" should be one-time triggers
- Without state change, `_physics_process()` continues executing movement/detection code
- Setting `state = State.DEAD` and `is_alive = false` stops all processing

**Pattern:**
```gdscript
if global_position.x > 1150:
    reached_end.emit(self)
    state = State.DEAD       # Stop processing
    is_alive = false         # Mark for cleanup
```

---

### 5. Checkpoint Detection Needs Position Comparison Per Frame

**Problem:** Checkpoint positions defined in lane but never checked against unit positions — game never paused at checkpoints.

**Decision:** **Add `_physics_process()` to level.gd that checks if all alive units have passed checkpoint x-position.**

**Rationale:**
- Checkpoints are spatial triggers, not signal-based events
- Need continuous position checking during BATTLE phase only
- Only trigger when ALL alive units past checkpoint (stragglers shouldn't advance phase)
- Track current checkpoint index to avoid re-triggering same checkpoint

**Implementation:**
```gdscript
var _current_checkpoint_index: int = 0

func _physics_process(_delta: float) -> void:
    if game_manager.phases.current_phase != PhaseManager.Phase.BATTLE:
        return
    
    if _current_checkpoint_index >= game_manager.phases.MAX_CHECKPOINTS:
        return
    
    var alive_units: Array[Node2D] = []
    for unit in deployer.deployed_units:
        if is_instance_valid(unit):
            alive_units.append(unit)
    
    if alive_units.is_empty():
        return
    
    var checkpoint_x: float = battlefield.get_lane(0).checkpoint_positions[_current_checkpoint_index]
    var all_past: bool = true
    for unit in alive_units:
        if unit.global_position.x < checkpoint_x:
            all_past = false
            break
    
    if all_past:
        _current_checkpoint_index += 1
        game_manager.phases.reach_checkpoint()
```

---

### 6. Lose Condition Must Check Both Queue AND Deployed Units

**Problem:** `_check_lose_condition()` only checked `deployer.is_deploying`, which doesn't account for units still in queue.

**Decision:** **Lose only when queue is empty AND no alive deployed units remain.**

**Rationale:**
- `is_deploying` flag only tracks deployment timer state, not queue contents
- Units can still be in queue even when deployer paused/stopped
- Must iterate deployed_units to count alive (using `is_instance_valid()`)

**Pattern:**
```gdscript
func _check_lose_condition() -> void:
    var alive_count := 0
    for unit in deployer.deployed_units:
        if is_instance_valid(unit):
            alive_count += 1
    
    if game_manager.units.unit_queue.is_empty() and alive_count == 0:
        _trigger_lose()
```

---

## Impact

These fixes resolved:
- 2 critical runtime errors (signal argument mismatch)
- Broken win/lose detection (game never ended)
- Broken checkpoint system (no mid-level pauses)
- Broken level select UI (layout issues)

All 9 bugs from playtesting now fixed.

---

## Future Considerations

- Consider abstracting signal-pause pattern into helper method to prevent future ordering bugs
- Document Control/CanvasLayer requirement in UI creation guidelines
- Add validation harness scenario to test win/lose/checkpoint conditions
