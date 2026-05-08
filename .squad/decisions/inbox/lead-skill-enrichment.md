### 2025-07-15: Enriched Validation SKILL.md Files for Sub-Agent Use

**By:** Lead (Game Architect)

**What:** Enriched all three SKILL.md files in `submodules/agentic_godot_validation/.github/skills/` so they are self-contained for sub-agents who read them via `.squad/skills/` symlinks.

**Key additions:**
- `author-validation-scenario`: Full step op reference table, JSON schema fields, comparator list, pipeline source/op/assert details, harness controller pattern with `get_observed_state()` shape, real examples
- `debug-validation-failure`: Artifact locations, summary.json/event_log.json/scene_tree.json reading guides, signal facts shape, failure pattern diagnostic table
- `install-agentic-godot-validation`: Squad symlink step with PowerShell commands

**Why:** Sub-agents spawned via `task` tool cannot call the `skill` tool — they can only read files. The original ~29-line SKILL.md files said what to do but not how. Without inline schema details and examples, sub-agents had to guess or ask for help, producing incorrect scenarios and harnesses.

**Impact:** All sub-agents (Builder, Validator) reading these skills now have enough context to author scenarios, debug failures, and install the validation kit without needing companion docs.
