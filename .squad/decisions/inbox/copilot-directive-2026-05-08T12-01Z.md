### 2026-05-08T12:01Z: User directives — structural improvements
**By:** Brian (via Copilot)
**What:**
1. Template repo must include `squad.agent.md` (from `squad upgrade`) so Copilot CLI discovers Squad automatically in new prototypes.
2. Humans do play-testing ONLY — never QA/bug testing. All code changes MUST include validation scenarios. This is the point of the validation framework.
3. Squad agent model selection returns to `auto` (remove the opus-4.6 session-wide override).
4. Agents must push to GitHub (origin) at the end of their work batch. This is standard operating procedure.
**Why:** User request — prepping the system for better future development across prototypes.
