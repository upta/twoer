# Decision: Win Screen Scenario Validates Overlay Architecture

**By:** Validator

**What:** The `win_screen.json` scenario explicitly validates that the win overlay uses a CanvasLayer with `layer >= 10`. This is an architectural assertion, not just a visibility check — it ensures the overlay renders ABOVE all game UI (which lives on layer 1).

**Why:** Brian reported text rendering behind UI elements. The root cause is that a plain Label node shares z-ordering with game content. The fix (ResultOverlay CanvasLayer at layer 10) is validated by checking the layer value, not just visibility. If someone later reduces the layer, this scenario catches it.

**Implication for Builder:** `level.gd._trigger_win()` must be updated to:
1. Set `$ResultOverlay.visible = true`
2. Set `$ResultOverlay/ResultLabel.text = "Victory! You breached the defenses!"`

The legacy `$WinLabel` approach will cause the scenario to fail on the `result_overlay_visible` assertion. This is intentional — the scenario defines the contract for the fixed implementation.
