# NeXT UI Plugin

This directory contains the Vue.js-based UI plugin for NeXT (Next-Gen Extended Tooling) that integrates with Duet Web Control (DWC).

## Phase 2.1 Implementation Status

✅ **Completed:**
- Plugin scaffolding and directory structure
- `plugin.json` manifest file for DWC registration
- Main Vue plugin entry point (`src/index.ts`)
- Base component with common functionality (`BaseComponent.vue`)
- Main layout component (`NeXT.vue`)
- Core Status Widget for persistent machine status display
- Action Confirmation Widget for M1000 dialog integration
- Component registration system for modular organization
- Localization support (English)
- Integration with NeXT global variables

## Components

### Core Components
- **`NeXT.vue`**: Main dashboard layout with tabbed interface
- **`BaseComponent.vue`**: Foundation component with common properties and methods

### Panel Components
- **`StatusWidget.vue`**: Persistent status bar showing tool, WCS, spindle, and position
- **`ActionConfirmationWidget.vue`**: Non-blocking dialog interface for M1000 dialogs
- **`MachineStatusPanel.vue`**: Detailed machine and NeXT system status

### Placeholder Components
- **`inputs/`**: Ready for Phase 2.2 input components (configuration UI)
- **`overrides/panels/`**: Ready for DWC panel replacement components
- **`overrides/routes/`**: Ready for DWC route override implementation

## Key Features

1. **Vue 2.7 Architecture**: Clean, modern Vue.js structure
2. **DWC Integration**: Proper plugin registration and store integration
3. **Persistent UI**: Non-blocking status and dialog widgets
4. **Global Variable Integration**: Direct access to NeXT backend variables
5. **Modular Design**: Component-based architecture for easy extension
6. **Localization Ready**: i18n support with English strings

## Dialog System Integration

The Action Confirmation Widget integrates with the M1000 dialog system from PR #16:
- Displays persistent dialogs instead of blocking modals
- Connects to `nxtDialogActive`, `nxtDialogMessage`, etc. global variables
- Provides responsive button interface for user actions

## Next Phases

- **Phase 2.2**: Configuration UI implementation
- **Phase 3**: Probing interface and result management
- **Later**: Panel and route overrides for full DWC integration

## Build Process

The UI requires compilation using the DuetWebControl build system. See `docs/BUILD.md` for historical build process documentation.