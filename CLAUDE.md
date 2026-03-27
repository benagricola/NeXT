# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

NeXT (Next-Gen Extended Tooling) is a CNC operations system built on RepRapFirmware (RRF) v3.6+ for the Millennium Machines Milo V1.5. It provides workpiece/tool probing, tool changes, tool setting, spindle control, and coolant management through G-code macros and a DuetWebControl (DWC) UI plugin. This is for CNC machines, not 3D printers.

The codebase has two languages: **RRF Meta G-code** (macros) and **TypeScript/Vue** (UI plugin). The G-code is not standard — it uses RRF's extended meta commands with variables, conditionals, and loops.

## Build & Development Commands

### Building a release (macros + UI plugin)
```bash
dist/release.sh <zip-name> <path-to-DuetWebControl-repo>
# Example: dist/release.sh next-release ../DuetWebControl
```
This requires the DuetWebControl repository as a sibling or specified path. The script:
1. Copies macros to an SD card layout under `sys/`
2. Builds the UI plugin via DWC's `npm run build-plugin`
3. Packages everything into a ZIP for upload to the Duet board

### UI development
```bash
# From the DuetWebControl directory (sibling repo):
cd DuetWebControl && npm run dev    # ~60s initial compile, serves at localhost:8080
# NeXT/ui/ must be symlinked into DuetWebControl/src/plugins/NeXT
# If the symlink doesn't exist, run: node add-next.js

# Type checking:
cd ui && npx tsc --noEmit
```

### Live machine testing
```bash
# Upload release to Duet board
curl -X POST --data-binary @"dist/millennium-os.zip" "http://<DUET_IP>/rr_upload?name=0:/sys/millennium-os.zip"
# Install (triggers board restart)
curl "http://<DUET_IP>/rr_gcode?gcode=M997 S2"
# Send G-code
curl "http://<DUET_IP>/rr_gcode?gcode=G28"
# Check replies
curl "http://<DUET_IP>/rr_reply"
```
There are no automated tests. All testing is on physical hardware with operator confirmation required before any machine movement.

## Architecture

### Layer 1: G-code Macros (`macros/`)

All macros are RRF Meta G-code. They are copied to the Duet's `/sys/` directory at build time.

| Directory | Purpose | Key files |
|-----------|---------|-----------|
| `system/` | Initialization, job control | `nxt.g` (entrypoint, called from config.g) -> `nxt-vars.g` (all globals) -> `nxt-boot.g` (sanity checks). Also `pause.g`, `resume.g`, `cancel.g` |
| `probing/` | 13 touch probe measurement cycles | `G37.g` (tool length), `G6500.g` (bore), `G6501.g` (boss), `G6502.g` (rect pocket), `G6510.g` (single surface), `G6512.g` (probe down), `G6550.g` (vise corner) |
| `tooling/` | 3-stage tool change state machine | `tfree.g` -> `tpre.g` -> `tpost.g` with automatic relative offset calculation via session cache |
| `spindle/` | Safe spindle wrappers with dwell | `M3.9.g` (CW+wait), `M4.9.g` (CCW+wait), `M5.9.g` (stop+decel) |
| `coolant/` | Flood/mist/air with state persistence | `M7.g`, `M8.g`, `M9.g` (saves/restores pin states across pause/resume) |
| `utilities/` | Helpers | `G27.g` (park), `M5000.g` (tool-compensated position), `M6515.g` (limit check) |
| `daemon/` | Background tasks | `nxt-daemon.g` |

**Global state**: All macros communicate through `nxt`-prefixed global variables defined in `nxt-vars.g`. Feature flags (`nxtFeatureTouchProbe`, `nxtFeatureToolSetter`, `nxtFeatureCoolantControl`) gate optional functionality.

### Layer 2: UI Plugin (`ui/`)

Vue 2.7 + Vuetify plugin for DuetWebControl v3.6.1. Registered as 4 panels:

- **MachineStatusPanel** (Control menu) — system status, positions, feature availability
- **ConfigurationPanel** (Settings menu) — spindle, touch probe, tool setter, coolant setup. Writes to `/sys/nxt-user-vars.g` on the Duet
- **StockPreparationPanel** (Job menu) — CAM-like facing toolpath generator with Three.js 3D preview, Web Worker for computation, G-code export
- **ProbingPanel** (Control menu) — placeholder for future probing UI

Key supporting components: `BaseComponent.vue` (shared computed properties for all panels), `GCodeViewer3D.vue` (Three.js viewer), `ActionConfirmationWidget.vue` (non-blocking M291 dialog handler), `StatusWidget.vue` (persistent status bar).

Toolpath generation lives in `ui/src/utils/toolpath.ts` (pattern algorithms) and `ui/src/utils/gcode.ts` (G-code output). Background computation in `ui/src/workers/toolpath.worker.ts`.

### Layer 3: Post-Processors (`post-processors/`)

- **FreeCAD**: `next_post.py` (~3000 lines Python)
- **Fusion 360**: `next.cps` + `milo-v1.5-std.mch`

Both output the NeXT G-code dialect. They assume firmware handles tool changes, WCS setting, and safety — they only emit G-code certain to be safe.

### Data Flow

Macros use `nxt*` global variables for inter-macro state. The RRF object model (`move.axes`, `tools`, `sensors.probes`, `spindles`, etc.) is the source of truth for machine state. The UI reads/writes globals via `sendCode()` which executes G-code on the machine. Configuration persists to `nxt-user-vars.g` on the Duet's SD card.

## Critical G-code Coding Rules

**Read `docs/CODE.md` completely before writing any macro code.** The most important rules:

1. **ALL expressions must be in curly braces `{}`** — this is the #1 source of bugs:
   ```gcode
   ; CORRECT
   var x = { 0 }
   if { exists(param.S) && param.S > 0 }
   echo { "Position: " ^ var.x }
   G0 X{var.x} Y{var.y}

   ; WRONG — will silently fail or produce incorrect results
   var x = 0
   if exists(param.S) && param.S > 0
   echo "Position: " ^ var.x
   ```

2. **Variable names**: `nxt` prefix, camelCase. RRF allows letters, digits, and underscores but the project convention uses camelCase without underscores.

3. **Global variable lifecycle**: Declare once with `global` in `nxt-vars.g`, update with `set global.<name> = { value }` everywhere else. Using `global` on an already-declared name errors. Using `set` on an undeclared name errors.

4. **CNC mode and parentheses**: Since NeXT runs in CNC mode, `()` outside `{}` are treated as G-code comments. Always wrap meta command expressions in `{}` — this is both a style requirement and functionally necessary whenever `()` appear (e.g., function calls like `exists()`, `abs()`, `ceil()`).

5. **`^` is string concatenation, not exponentiation**: Use `square()`, `pow()`, or `var.x * var.x`.

6. **Macro naming**: User-callable macros must be G/M-code format (`G37.g`, `M6515.g`). Never create named macros requiring `M98` calls. Wrapper macros use decimal extensions (`M3.9`, `M5.9`).

7. **No dynamic command execution**: You cannot build a command string and execute it in RRF.

8. **Use `iterations`** instead of custom loop counters. Handle sparse arrays with null checks.

9. **Line length limit**: 250 characters. Do not split expressions across lines.

10. **Parameter naming**: Avoid axis letters (X/Y/Z/A/B/C) for non-coordinate parameters. Use P for index, F for feed, R for retries, I for ID.

11. **Required dimensions**: Never provide defaults for workpiece-dependent parameters (width, height, depth).

12. **Parking**: Use `G27 Z1` before tool changes, spindle start/stop, probing, and tool length measurements.

13. **G6512 calls must include `I` param**: Every call to the single-axis probing primitive G6512 must pass `I{global.nxtTouchProbeID}` or `I{global.nxtToolSetterID}`.

**See `docs/CODE.md` Section 14 (Common Pitfalls)** for detailed examples of every mistake above, with correct and incorrect patterns.

## Development Workflow

- All development targets `benagricola/NeXT` `main` branch
- Feature branches for all work (e.g., `feature/probing-engine`, `fix/tool-change-logic`)
- Direct commits to `main` only for docs and scaffolding
- Squash and merge; aim for one commit per feature
- Self-review mandatory after PR creation using `gh pr diff`
- Never self-approve PRs — leave for human review
- When removing dead code, do not add inline comments about what was removed
- Use `export PAGER=` or `| tee` with `gh` commands to avoid pager issues

## Key References

- **RRF G-codes**: https://docs.duet3d.com/User_manual/Reference/Gcodes
- **RRF Meta G-code**: https://docs.duet3d.com/User_manual/Reference/Gcode_meta_commands
- **RRF Object Model**: https://github.com/Duet3D/RepRapFirmware/wiki/Object-Model-Documentation
- **Vue 2.7**: https://v2.vuejs.org/
- **Vuetify 2.x**: https://v2.vuetifyjs.com/
- `docs/CODE.md` — complete coding style guide (the authoritative reference)
- `docs/FEATURES.md` — feature requirements and implementation status
- `docs/ROADMAP.md` — phased development plan
- `docs/TESTING.md` — live machine testing procedures
- `docs/TOOLSETTING.md` — tool setting and Z-offset workflow
- `docs/CALIBRATION.md` — machine calibration guide
- `docs/UI_DEVELOPMENT.md` — UI plugin development setup
