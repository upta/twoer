### itch.io Web Deploy Pipeline

**By:** Builder
**Date:** 2026-05-15

**What:** Added GitHub Actions workflow (`.github/workflows/deploy.yml`) that builds the Godot web export and pushes to itch.io on every push to main. Also created `src/export_presets.cfg` and unignored it.

**Requirements for Brian:**
1. Set `ITCHIO_API_KEY` repo secret (get from https://itch.io/user/settings/api-keys)
2. Set `GODOT_SUBMODULE_PAT` repo secret (GitHub PAT with repo access for private submodules)
3. Verify `barichello/godot-ci:4.6` Docker tag exists — may need `4.6.0` or `4.6-stable` depending on image availability

**Why:** Enables continuous deployment of playable web builds to itch.io for playtesting without manual export steps.
