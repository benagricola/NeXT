# M291 Dialog Override Investigation

## Overview

This document outlines the investigation into overriding M291 dialog handling in Duet Web Control (DWC) from a plugin, specifically for integrating dialog displays into a persistent UI section rather than blocking modal dialogs.

## Current M291 Dialog System

### How DWC Handles M291 Dialogs

1. **RRF M291 Command**: RepRapFirmware executes M291 commands that create message box objects in the object model
2. **Object Model State**: The message box data is stored in `state.messageBox` with properties:
   - `message`: Dialog message content
   - `title`: Dialog title  
   - `mode`: Dialog type (MessageBoxMode enum)
   - `choices`: Array of button choices for multi-choice dialogs
   - `seq`: Sequence number for response correlation
   - Other properties for input validation, axis controls, etc.

3. **DWC MessageBoxDialog**: A Vue component (`/src/components/dialogs/MessageBoxDialog.vue`) watches `state.messageBox` and displays modal dialogs
4. **User Response**: User interactions send M292 commands back to RRF with response data

### Key Files in DWC
- `/src/components/dialogs/MessageBoxDialog.vue` - Main dialog component
- `/src/store/machine/model.ts` - Object model state management
- `/src/App.vue` - Includes `<message-box-dialog />` globally

## Plugin Override Mechanisms in DWC

DWC provides several mechanisms for plugins to customize behavior:

### 1. Component Injection
```typescript
injectComponent(name: string, component: Component)
```
- Injects components into the main app for global rendering
- Components are rendered in `App.vue` using `<component v-for="component in injectedComponentNames" :is="component" :key="component" />`

### 2. Component Replacement  
- Register Vue components with same names as built-in components
- DWC will use the plugin component instead of the built-in one
- Used by legacy MillenniumOS for panel overrides

### 3. Route Registration
```typescript
registerRoute(component: Component, route: RouteConfig)
```
- Adds new menu items and routes to DWC
- Standard way to add plugin functionality

## NeXT Current Dialog Pattern

NeXT already implements a smart fallback pattern:

```gcode
if { global.nxtUiReady }
    M1000 P{message} R{title} K{choices} F{flag}
else
    M291 P{message} R{title} S{mode} K{choices} F{flag}
```

This allows NeXT macros to use custom dialog handling when the UI is available, falling back to standard M291 dialogs otherwise.

## Recommended Implementation Approach

### Option 1: Component Replacement (Recommended)
Replace the built-in MessageBoxDialog with a custom version that:

1. **Detects NeXT Context**: Check if `global.nxtUiReady` is true in the object model
2. **Conditional Rendering**: 
   - For NeXT dialogs (when `nxtUiReady = true`): Render in a persistent UI section
   - For standard dialogs: Use traditional modal display
3. **Seamless Integration**: Maintain all existing functionality while adding custom display

### Option 2: Parallel Component Injection  
Inject a parallel dialog handler that:
1. Watches `state.messageBox` alongside the built-in component
2. Intercepts and handles NeXT-specific dialogs
3. Allows built-in component to handle standard dialogs

### Option 3: M1000 Macro Implementation
Create a custom M1000.g macro that:
1. Stores dialog data in NeXT global variables
2. Triggers UI updates through object model changes
3. Provides M292-compatible responses

## Technical Implementation Details

### MessageBoxDialog Override Structure
```typescript
// Custom NeXT MessageBoxDialog
export default Vue.extend({
  computed: {
    currentMessageBox(): MessageBox | null { 
      return store.state.machine.model.state.messageBox; 
    },
    isNeXTDialog(): boolean {
      // Check if NeXT UI is ready and this is a NeXT dialog
      return store.state.machine.model.global?.nxtUiReady === true;
    }
  },
  // ... existing MessageBoxDialog logic with conditional rendering
});
```

### Plugin Registration  
```typescript
// In plugin index.ts
import CustomMessageBoxDialog from "./CustomMessageBoxDialog.vue";

// Replace built-in component
Vue.component("message-box-dialog", CustomMessageBoxDialog);
```

### Persistent UI Integration
The custom dialog component would render messages in the NeXT UI's persistent section while maintaining:
- Full M292 response compatibility
- All existing dialog modes (input, multi-choice, etc.)
- Proper accessibility and keyboard navigation
- Emergency stop functionality for persistent dialogs

## Benefits of This Approach

1. **Non-Blocking UI**: Dialogs don't block the entire interface
2. **Better User Experience**: Persistent dialogs allow monitoring other UI elements
3. **Backward Compatibility**: Standard M291 dialogs still work normally
4. **Incremental Adoption**: NeXT macros can opt-in with `nxtUiReady` checks

## Limitations and Considerations

1. **Plugin Development Complexity**: Requires building and packaging UI plugins
2. **Version Compatibility**: Plugin must be compatible with DWC versions
3. **Testing Requirements**: Need to test both dialog modes thoroughly
4. **Emergency Stop Access**: Persistent dialogs need accessible emergency stop

## Implementation Status

### ✅ Completed
1. **M1000.g macro**: Created custom dialog handling macro with fallback to M291
2. **Dialog variables**: Added NeXT dialog state variables to `nxt-vars.g`
3. **Plugin example**: Complete DWC plugin example with component replacement
4. **Technical documentation**: Comprehensive investigation and implementation guide

### 📁 Code Examples
- **M1000.g**: `/macros/system/M1000.g` - Custom dialog macro with UI integration
- **Plugin Example**: `/docs/next-dwc-plugin-example/` - Complete DWC plugin implementation
- **Variable Definitions**: Updated `/macros/system/nxt-vars.g` with dialog state

### 🔄 Next Steps (Future Implementation)
1. Build and package the DWC plugin using DWC's build system
2. Test dialog override functionality across different dialog scenarios
3. Implement plugin installation and distribution mechanism
4. Add comprehensive testing for both modal and persistent dialog modes
5. Document plugin compatibility requirements and installation process

## Conclusion

Overriding M291 dialog handling is **technically feasible** using DWC's component replacement mechanism. The recommended approach is to replace the MessageBoxDialog component with a custom version that provides conditional rendering based on the NeXT UI state, maintaining full backward compatibility while enabling persistent dialog display.