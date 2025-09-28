# NeXT Tool Change System

This directory contains the core tool change macros implementing the new relative-offset calculation system described in `TOOLSETTING.md`.

## RRF Tool Change Integration

These macros follow the RepRapFirmware tool change system as documented at:
https://docs.duet3d.com/User_manual/Tuning/Tool_changing

RRF automatically calls these macros during tool changes in this specific order:
1. `tfree.g` - Before freeing the current tool
2. `tpre.g` - Before selecting the new tool  
3. `tpost.g` - After selecting the new tool

## Core Tool Change Macros

### `tfree.g` - Tool Removal
- Executed by RRF before a tool is freed (unloaded)
- Implements "probe-on-removal" logic for standard cutting tools
- Measures tool length on toolsetter before removal for caching
- Handles probe tool removal with operator prompts

### `tpre.g` - Pre Tool Change
- Executed by RRF before tool change begins
- Provides operator guidance for tool installation
- Validates system state and required calibrations
- Handles both probe tools and cutting tools

### `tpost.g` - Post Tool Change
- Executed by RRF after tool change is complete
- Implements the core relative offset calculation logic
- Handles different scenarios: probe→cutter, cutter→cutter
- Applies calculated offsets to tools

## Supporting Macros

### `G37.g` - Automated Tool Length Measurement
- Updated version that works with the new relative offset system
- Measures tools on toolsetter and calculates appropriate offsets
- Integrates with the tool cache and delta machine system

### `manual-tool-measurement.g` - Manual Tool Length Measurement
- Fallback for systems without toolsetter
- Guides operator through manual Z-origin setting
- Clears tool offsets and sets WCS origins directly

### `calibrate-static-datum.g` - Static Datum Calibration
- One-time calibration of `nxtDeltaMachine`
- Establishes geometric relationship between toolsetter and reference surface
- Required for touch probe systems

### `babystep-delta.g` - Fine Delta Adjustment
- Allows fine adjustment of `nxtDeltaMachine` for thermal drift
- Safety-limited adjustments (±1.0mm maximum)
- Alternative to full recalibration

## Key Variables

- `nxtDeltaMachine`: Static Z distance between toolsetter and reference surface
- `nxtToolChangeState`: State tracking for tool change process (0-4)  
- `nxtPreviousToolOffset`: Previous tool's offset for relative calculations

Tool measurements are stored directly in RRF's tool offset system (`tools[toolNumber].offsets[2]`). If a tool's Z offset is 0, it indicates the tool needs measurement.

## Workflow Examples

### Initial Setup (Touch Probe System)
1. Configure toolsetter and reference surface positions
2. Run `calibrate-static-datum.g` with datum tool
3. System is ready for touch probe and cutting tools

### Standard Tool Change (Cutter A → Cutter B)
1. `tfree.g`: Measures Cutter A on toolsetter (if not cached), stores offset
2. Operator swaps tools physically
3. `tpre.g`: Guides operator through Cutter B installation
4. `tpost.g`: Measures Cutter B, calculates relative offset, applies to tool

### Touch Probe Calibration
1. Install touch probe via tool change
2. `tpost.g`: Measures probe against reference surface
3. Probe offset set to 0 (establishes WCS reference)

## Error Handling

- Validates required calibrations before tool changes
- Handles T-1 scenario (unmeasured tool → known tool)
- Provides clear error messages for missing configurations
- Falls back to manual measurement when automatic systems unavailable

## Integration

- Works with existing probing system (`G6512.g`)
- Compatible with both toolsetter and manual workflows
- Supports UI-based confirmations when `nxtUiReady = true` 
- Falls back to M291.9 dialogs when UI unavailable