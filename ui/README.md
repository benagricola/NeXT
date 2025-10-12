# NeXT UI Plugin

Vue.js-based UI plugin for NeXT (Next-Gen Extended Tooling) that integrates with Duet Web Control (DWC).

## Overview

The NeXT UI provides a modern, user-friendly interface for configuring and operating the NeXT CNC control system. It replaces the legacy G8000 configuration wizard with a comprehensive web-based interface.

## Key Components

### Configuration Panel (`ConfigurationPanel.vue`)

The Configuration Panel is the primary interface for system setup, replacing the G8000 wizard. It provides:

**Features Section:**
- Toggle switches for major features (Touch Probe, Tool Setter, Coolant Control)
- Instant updates to the object model

**Spindle Configuration:**
- Spindle ID selection
- Acceleration/deceleration time settings

**Touch Probe Configuration:**
- Sensor ID
- Probe tip radius (for horizontal compensation)
- Probe deflection value
- Access to deflection measurement wizard

**Tool Setter Configuration:**
- Sensor ID
- Position vector [X, Y, Z] editor

**Coolant Control Configuration:**
- Pin ID mappings for air, mist, and flood outputs

### Probe Deflection Wizard (`ProbeDeflectionWizard.vue`)

A step-by-step wizard that guides users through measuring probe deflection:

1. **Setup**: Prerequisites check
2. **Block Dimensions**: Input reference block dimensions
3. **Measure X**: Automated X-axis measurement
4. **Measure Y**: Automated Y-axis measurement
5. **Results**: Calculate deflection and apply to configuration

The wizard uses G6504 (Web probe) to measure both sides of a reference block and calculates deflection as the difference between known and measured dimensions.

## Configuration Workflow

### Direct Editing
All configuration values can be edited directly in the Configuration Panel. Changes are:
1. Validated in the UI
2. Sent to RRF via G-code commands: `set global.variableName = value`
3. Immediately reflected in the object model
4. Applied to all running macros

### Saving Configuration
The "Save Configuration" button will persist settings to `nxt-user-vars.g` (backend implementation pending).

### Loading Configuration
The "Reload" button refreshes the UI with current values from the object model.

## Integration with Backend

The UI integrates with backend macros through RRF's object model:

- **Reading Values**: Accessed via `this.nxtGlobals` computed property in components
- **Writing Values**: Sent via G-code commands through `this.sendCode()`
- **State Management**: All configuration stored in global variables defined in `nxt-vars.g`

### Global Variables Used

From `macros/system/nxt-vars.g`:

```gcode
; Features
global nxtFeatureTouchProbe
global nxtFeatureToolSetter
global nxtFeatureCoolantControl

; Spindle
global nxtSpindleID
global nxtSpindleAccelSec
global nxtSpindleDecelSec

; Touch Probe
global nxtTouchProbeID
global nxtProbeTipRadius
global nxtProbeDeflection

; Tool Setter
global nxtToolSetterID
global nxtToolSetterPos

; Coolant Control
global nxtCoolantAirID
global nxtCoolantMistID
global nxtCoolantFloodID
```

## Development

### Project Structure

```
ui/
├── src/
│   ├── components/
│   │   ├── base/           # BaseComponent with common functionality
│   │   ├── panels/         # Panel components (Status, Configuration, etc.)
│   │   ├── wizards/        # Wizard components (Probe Deflection, etc.)
│   │   └── overrides/      # DWC component overrides
│   ├── locales/           # Localization files
│   ├── index.ts           # Plugin entry point
│   └── NeXT.vue           # Main dashboard component
└── plugin.json            # DWC plugin manifest
```

### Adding New Configuration Fields

1. Add global variable to `macros/system/nxt-vars.g`
2. Add field to `localConfig` data in `ConfigurationPanel.vue`
3. Add form control in appropriate expansion panel
4. Wire up with `@blur="updateVariable('varName', localConfig.varName)"`
5. Add localization strings to `locales/en.json`

### Component Development

All components extend `BaseComponent` which provides:
- Access to RRF object model via store
- Computed properties for common data (axes, tools, globals)
- `sendCode()` method for executing G-code
- Helper methods for position calculations

## Testing

The UI cannot be tested in isolation as it requires:
1. RepRapFirmware v3.6+ running on a Duet board
2. DuetWebControl with plugin support
3. NeXT backend macros loaded

For development testing:
1. Build the plugin using DWC build system
2. Deploy to DWC plugins directory
3. Test with actual machine or RRF simulation

## Build Process

The UI requires compilation using the DuetWebControl build system. See the main project README for build instructions.

## Future Enhancements

- Spindle control panel with start/stop buttons
- Coolant control panel with visual indicators
- WCS management interface
- Probing interface and results table
- Live position display improvements
