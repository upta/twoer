### Attack Line Visual Pattern

**By:** Builder

**What:** Tower attack indicators use ephemeral Line2D children with tween fade-out (0.15s). No scene changes needed — lines are created/destroyed at runtime via `_show_attack_line()`. Tower color is reused for the line color at 70% opacity.

**Why:** Lightweight approach — no additional scene nodes, no timers, no object pooling. Tweens handle cleanup automatically. If we need pooling later for performance (many towers firing simultaneously), we can cache lines instead of creating new ones each shot.

**Implications:**
- Each fire creates N Line2D nodes (N = targets hit). For AoE with many targets this could spike. Monitor if needed.
- Line positions are set once at fire time (no tracking moving targets). This is intentional — it's a "muzzle flash" style indicator, not a beam.
