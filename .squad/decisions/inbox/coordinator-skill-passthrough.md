### 2026-05-08T08:20:00Z: Skill passthrough pattern for sub-agents
**By:** Squad Coordinator
**What:** Sub-agents spawned via `task` do NOT have access to the `skill` tool — it only works in the main conversation. When a sub-agent needs skill guidance (e.g., `author-validation-scenario`, `debug-validation-failure`), the coordinator must:
1. Read the skill file at `.github/skills/{skill-name}/SKILL.md`
2. Inline the full SKILL.md content into the sub-agent's spawn prompt under a `## SKILL: {name}` section
3. Never instruct sub-agents to "invoke" or "use" the skill tool — they can't

**Skills available in this project:**
- `.github/skills/author-validation-scenario/SKILL.md` — for creating harnesses, controllers, scenarios
- `.github/skills/debug-validation-failure/SKILL.md` — for diagnosing failing validation runs

**Why:** Discovered that Validator couldn't follow instructions to invoke the skill tool. The tool is main-conversation-only by design.
