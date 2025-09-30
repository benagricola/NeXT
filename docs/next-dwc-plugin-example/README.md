# NeXT DWC Plugin Example

This directory contains example code showing how to create a DWC plugin that overrides M291 dialog handling for NeXT integration.

## File Structure

```
next-dwc-plugin-example/
├── plugin.json                    # Plugin manifest
├── index.ts                       # Plugin entry point  
├── components/
│   └── NeXTMessageBoxDialog.vue   # Custom dialog component
└── types/
    └── next.d.ts                  # TypeScript definitions
```

## Key Implementation Points

1. **Component Replacement**: Replace the built-in `message-box-dialog` component
2. **Conditional Rendering**: Show persistent dialogs for NeXT, modal for others
3. **State Management**: Monitor both `state.messageBox` and NeXT global variables
4. **Response Handling**: Maintain M292 compatibility for all dialog types

## How It Works

### Dialog Detection
The plugin watches two sources for dialog events:
- **Standard M291**: Via `store.state.machine.model.state.messageBox`
- **NeXT M1000**: Via NeXT global variables like `global.nxtDialogActive`

### Conditional Display
- **Modal dialogs**: Used for critical messages or when NeXT UI is not ready
- **Persistent dialogs**: Used for NeXT dialogs when UI is ready, shown in a fixed position

### Response Handling
- **M291 dialogs**: Send M292 responses directly to RRF
- **M1000 dialogs**: Set `global.nxtDialogResponse` for the macro to read

## Building the Plugin

1. Copy this directory to DWC's `src/plugins/` directory
2. Run DWC's plugin build script: `npm run build-plugin NeXTDialogOverride`
3. The built plugin will be available for installation in DWC

## Installation

1. Upload the built plugin file to DWC via Settings > Plugins
2. Restart DWC to load the plugin
3. Verify that `global.nxtUiReady` is set to `true` in NeXT macros

See the main investigation document for detailed technical analysis.