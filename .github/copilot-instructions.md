# NeXT AI Coding Guidelines

## Architecture Overview
NeXT (Next-Gen Extended Tooling) extends RepRapFirmware (RRF) v3.6+ with meta G-code macros for CNC operations. Core components:
- **Macros** (`macros/`): G-code files with logic for probing, spindle, coolant, etc. Use vectors for data handling.
- **System** (`macros/system/`): Initialization (`nxt-boot.g`), globals (`nxt-vars.g`), daemon tasks.
- **UI** (`ui/`): JavaScript plugin for Duet Web Control integration.
- **Post-Processors** (`post-processors/`): Fusion360/FreeCAD scripts for extended G-codes (e.g., `M3.9`).

Data flows via global variables (e.g., `nxtProbeResults`) and macro calls (e.g., `M5000` for positions). Designed for simplicity: wrapper macros add safety to RRF commands.

## Development Repository
**Important**: NeXT development has moved to a dedicated repository at `benagricola/NeXT`. All PRs and development work should target the `main` branch of that repository, not this one.

## Development Workflow
- **Branching**: Feature branches from `main`, merge via PRs. Squash commits for clean history.
- **PR Process**: Self-review with `gh pr diff --json` and `gh pr review --comment`. Focus on logic errors, complexity, dead code. Pipe `gh` output to `tee` to avoid pagers.
- **Testing**: Live on machines (see `docs/TESTING.md`). No automated tests; use `echo` for debugging.
- **Build/Deploy**: No build step necessary pre-commit; Builds run on github once merged. For testing, run dist/release.sh and upload to RRF, following `docs/TESTING.md`.

## RRF Meta Gcode
- **System G- and M-Codes**: Available system gcodes are documented at https://docs.duet3d.com/User_manual/Reference/Gcodes and should be referred to for the correct usage and parameters of each code.
- **Meta G-Code**: RRF supports an extended G-Code language definition that includes variables, conditionals, loops, and functions. This is documented at https://docs.duet3d.com/User_manual/Reference/Gcode_meta_commands. NeXT macros are designed to leverage these features for clarity and maintainability.

## Coding Conventions
- **Variables**: `nxt*` prefix for globals (e.g., `nxtProbeDeflection`). camelCase, descriptive names.
- **Expressions**: Wrap ALL expressions in `{}` (e.g., `if { exists(param.X) && param.X > 0 }`, `var myVar = { 5 }).
- **Macros**: Wrapper pattern for RRF commands (e.g., `M3.9` calls `M3`). Use vectors for multi-axis data (e.g., `targetVector` in `G6512.g`).
- **Structure**: Headers with usage/parameters. Abort on errors with clear messages, prefixed with the macro name.
- **Phase-Based Implementation**: Follow `docs/ROADMAP.md` phases; implement features incrementally.

## Integration Points
- **RRF Compatibility**: Assumes 3-4 axes; ignores extra axes in commands. Use `M5000` for positions, not `lastStopPosition`.
- **UI Fallback**: Check `global.nxtUiReady` for UI features; provide manual alternatives.
- **External Tools**: Post-processors output extended codes; CAD workflows in `docs/`.

Reference: `docs/CODE.md` for style, `docs/DEVELOPMENT.md` for workflows, `macros/probing/G6512.g` for vector patterns.