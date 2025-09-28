# NeXT UI Plugin

This directory contains the Vue.js UI plugin for NeXT (Next-Gen Extended Tooling).

## Overview

The UI plugin provides a modern, integrated interface for NeXT functionality within Duet Web Control (DWC). It replaces the legacy G-code based configuration system with an intuitive web interface.

## Key Components

### Core Components
- **NeXT.vue** - Main dashboard layout component
- **BaseComponent.vue** - Shared functionality for all components

### Widgets
- **StatusWidget** - Displays current tool, WCS, spindle status, and position
- **ActionConfirmationWidget** - Replaces blocking M291 dialogs with UI confirmations

### Panels
- **ProbeResultsPanel** - Shows probe results with WCS management
- **ProbingCyclesPanel** - Interface for all probing operations
- **ConfigurationPanel** - Settings management (replaces G8000 wizard)

### Input Components
- **AxisInput** - Multi-axis coordinate input component

## Integration with NeXT Backend

The UI integrates with NeXT macros through RRF global variables:

- `global.nxtUiReady` - Set when UI is loaded and available
- `global.nxtPendingAction` - Action requiring user confirmation
- `global.nxtActionResponse` - User response to pending actions
- `global.nxtProbeResults` - Array of probe results for display
- All configuration variables use `nxt*` prefix

## Build Requirements

The UI plugin is built using the DuetWebControl build system:

1. Clone the [DuetWebControl repository](https://github.com/Duet3D/DuetWebControl)
2. Run `npm install` in the DWC repository
3. Use `npm run build-plugin <path-to-nxt-ui>` to build the plugin

The release script (`dist/release.sh`) automates this process when the DWC repository is available.

## Development

For development and testing:

1. Make changes to `.vue` and `.ts` files
2. The plugin uses Vue 2.7 with TypeScript
3. All components extend BaseComponent for common functionality
4. Use Vuetify components for UI consistency
5. Follow DWC plugin conventions for integration

## Fallback Behavior

The UI is designed to work alongside Phase 1 core macros. If the UI is not loaded, macros fall back to M291 dialogs for user interaction.