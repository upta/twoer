# Phase 7: Main Game Loop Decision

**Decision:** Use dynamic scene instantiation in main.gd rather than scene switching via SceneTree.change_scene_to_file()

**Rationale:**
- Gives full control over lifecycle (can unpause tree, cleanup before switching)
- Avoids tree reload overhead (main node persists across level select/gameplay transitions)
- Enables custom transition logic (2-second delay timer before returning to menu)
- Simpler signal connection management (level signals connected in _on_level_selected)

**Alternative Considered:**
- Using SceneTree.change_scene_to_file() to swap main.tscn with level.tscn
- Rejected because it loses state in main, harder to coordinate unpause logic, and would require separate "level loader" scene

**Impact:**
- Clean separation: level_select and level are child scenes, main orchestrates
- Easy to add fade transitions or loading screens later
- Pause state properly managed (unpause when returning to menu)
