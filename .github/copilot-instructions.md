# Copilot Instructions

This is a Godot game prototype using the [agentic-godot-validation](https://github.com/upta/agentic-godot-validation) kit for automated gameplay validation.

## Project Structure

- `src/` — the Godot project root (`project.godot` lives here)
- `src/game/` — gameplay scenes and scripts
- `src/bootstrap/` — app entry point with test-mode routing
- `src/validation/` — harnesses, scenarios, and harness controllers
- `src/addons/agentic_godot_validation/` — symlinked validation runtime (do not edit directly)
- `submodules/agentic_godot_validation/` — git submodule source
- `tools/` — symlinked validation runner scripts

## Key Conventions

- The app root routes between the game and the validation test bootstrap via `--test-mode` CLI flag
- Validation scenarios are JSON contracts in `src/validation/scenarios/`
- Harness scenes live in `src/validation/harnesses/` with controllers in `src/validation/scripts/harness_controllers/`
- Run scenarios with `./tools/run_scenario.ps1 -Scenario src/validation/scenarios/<name>.json -GodotExe <path>`
- Do not modify files under `src/addons/agentic_godot_validation/` — changes belong in the submodule repo

## Validation Asset Rules

- Expose semantic game state through harness controllers using `get_observed_state()`
- Prefer `nodes`, `metrics`, and `signals` under `harness_state`
- Prefer `assert_value` and `assert_pipeline` over custom scenario operations
- Keep harnesses deterministic and minimal
