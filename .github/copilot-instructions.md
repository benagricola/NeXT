# NeXT AI Coding Guidelines

## Project Overview
NeXT (Next-Gen Extended Tooling) is a complete rewrite of MillenniumOS that extends RepRapFirmware (RRF) v3.6+ with meta G-code macros for CNC operations. This is designed specifically for CNC machines, not 3D printers.

### Core Architecture
- **Macros** (`macros/`): G-code files with logic organized by function:
  - `macros/system/`: Core initialization (`nxt-boot.g`), globals (`nxt-vars.g`), daemon tasks
  - `macros/probing/`: All probing cycles and probe-related functionality
  - `macros/spindle/`: Spindle control and safety wrappers
  - `macros/coolant/`: Coolant control (mist, flood, air blast)
  - `macros/tooling/`: Tool changing and length measurement
  - `macros/utilities/`: Parking, power control, general utilities
- **UI** (`ui/`): JavaScript plugin for Duet Web Control integration
- **Post-Processors** (`post-processors/`): Fusion360/FreeCAD scripts for extended G-codes
- **Documentation** (`docs/`): Comprehensive guides for development, testing, and features

### Data Flow & Design Philosophy
- Global variables with `nxt*` prefix for state management (e.g., `nxtProbeResults`)
- Macro calls for machine information (e.g., `M5000` for positions)
- **Simplicity First**: Wrapper macros add safety to RRF commands without complexity
- **Numerical Stability**: Algorithms prioritize accuracy, especially in probing operations
- **Single-Axis Probing**: Core principle - one axis movement per probing command

## Development Repository & Workflow

### Repository Structure
**Current Repository**: `benagricola/NeXT` - All development targets the `main` branch.

### Branching Strategy
- **Feature Branches**: Create from `main` for all new features
- **Direct Commits**: Only for documentation, initial scaffolding, or core loading scripts
- **Clean History**: Squash commits when merging; aim for one commit per feature

### Development Process
1. **Feature Planning**: Scope work to specific features from `docs/FEATURES.md`
2. **Branch Creation**: Descriptive names like `feature/probing-engine` or `fix/tool-change-logic`
3. **Implementation**: Follow phase-based approach from `docs/ROADMAP.md`
4. **Testing**: Live machine testing required (see `docs/TESTING.md`)
5. **Pull Request**: Self-review mandatory using `gh pr diff --json`
6. **Merge**: Squash and merge to `main`

### GitHub CLI Best Practices
- **Avoid Pagers**: Use `gh pr diff 220 | tee` or `export PAGER=` to prevent hanging
- **Structured Output**: Use `--json` flags for machine-readable data
- **Self-Review Focus**: Look for logic errors, complexity, dead code, and typos

## Technical Standards

### RRF Meta G-Code Development
- **System G/M-Codes**: Reference https://docs.duet3d.com/User_manual/Reference/Gcodes
- **Meta G-Code**: Leverage RRF's extended language features (variables, conditionals, loops)
- **Documentation**: https://docs.duet3d.com/User_manual/Reference/Gcode_meta_commands

### Coding Conventions (see `docs/CODE.md` for full details)
- **Variables**: 
  - Global: `nxt*` prefix, camelCase (e.g., `nxtProbeDeflection`)
  - Descriptive names over abbreviations
- **Expressions**: ALWAYS wrap in `{}`:
  - `if { exists(param.X) && param.X > 0 }`
  - `var myVar = { 5 }`
- **Macro Structure**:
  - Header comments with purpose, usage, and parameters
  - Early parameter validation
  - Use `abort` for fatal errors with descriptive messages
  - Prefix error messages with macro name
- **G-Code Extensions**:
  - Follow NIST standards where possible
  - Wrapper macros use decimal extensions (e.g., `M3.9` wraps `M3`)
  - Post-processors must output extended codes

### File Organization & Naming
- **System Files**: Use `nxt` prefix (e.g., `nxt-boot.g`, `nxt-vars.g`)
- **Macro Files**: Organized by function in appropriate subdirectories
- **Vector Usage**: Use vectors for multi-axis data handling
- **Comments**: Header blocks for each file, inline for complex logic

## Testing & Quality Assurance

### Testing Strategy
- **Live Machine Testing**: Primary testing method (see `docs/TESTING.md`)
- **No Automated Tests**: Use `echo` statements for debugging
- **Safety First**: Always test with soft materials first
- **Operator Confirmation**: Required for any machine movement

### Build & Release Process
- **Development**: No build step required for development
- **Release**: Automated via GitHub Actions on tag push
- **Local Testing**: Use `dist/release.sh` to create test packages
- **UI Compilation**: Requires DuetWebControl repository for plugin building

## Integration & Compatibility

### RRF Integration
- **Version Requirement**: RRF v3.6+ for meta G-code features
- **Axis Support**: Assumes 3-4 axes, ignores extras in commands
- **Position Queries**: Use `M5000` macro, not `lastStopPosition`
- **Daemon Integration**: Uses `daemon.g` for repetitive tasks (VSSC, etc.)

### UI Integration
- **Fallback Strategy**: Check `global.nxtUiReady` for UI availability
- **Manual Alternatives**: Always provide M291 dialogs as fallback
- **Plugin System**: Integrates with Duet Web Control plugin architecture

### External Tool Integration
- **Post-Processors**: Output extended G-codes for enhanced functionality
- **CAD Workflows**: Documented in `docs/` directory
- **Version Checking**: Post-processors validate NeXT version compatibility

## Development Phases & Feature Implementation

### Current Phase Focus
Follow `docs/ROADMAP.md` for implementation priority:
1. **Phase 0**: Foundation & cleanup ✅
2. **Phase 1**: Core system & probing engine (in progress)
3. **Phase 2**: Advanced features & UI integration
4. **Phase 3**: Final polish & optimization

### Feature Tracking
- Use `docs/FEATURES.md` for feature requirements and status
- Mark completed features with checkboxes
- Reference specific features in commit messages and PRs

## Key Reference Documents
- **Coding Style**: `docs/CODE.md` - Complete style guide and conventions
- **Development Process**: `docs/DEVELOPMENT.md` - Detailed workflow and PR process
- **Feature Requirements**: `docs/FEATURES.md` - Complete feature list and priorities
- **Implementation Roadmap**: `docs/ROADMAP.md` - Phase-based development plan
- **Testing Procedures**: `docs/TESTING.md` - Live machine testing guidelines
- **Legacy Documentation**: `docs/DETAILS.md` - Understanding existing MillenniumOS functionality
- **G-Code Reference**: `GCODE.md` - Custom G-code and M-code documentation

## Safety & Liability Considerations
- **Physical Hardware**: All testing involves real CNC machines
- **Safety First**: Operators must be present and ready for emergency stop
- **Incremental Testing**: Test with soft materials before actual workpieces
- **Clear Messaging**: Error messages must be descriptive and actionable
- **Confirmation Required**: Any machine movement requires explicit operator confirmation