# NeXT UI Plugin Development Guide

## Overview
This guide explains how to develop the NeXT UI plugin within the DuetWebControl workspace. The NeXT UI is a Vue 2.7 plugin that integrates with DuetWebControl v3.6.1 to provide CNC-specific functionality for RepRapFirmware.

## Workspace Structure

The NeXT repository contains the UI plugin source code, which is **symlinked** into the DuetWebControl repository for development:

- **NeXT UI Source**: `/home/ben/Documents/CAD/Millennium Milo/Repos/NeXT/ui/`
- **DWC Plugin Location**: `/home/ben/Documents/RRF/DuetWebControl/src/plugins/NeXT` (symlink to NeXT UI source)
- **DWC Repository**: `/home/ben/Documents/RRF/DuetWebControl/`

### Important Files

```
NeXT/ui/
├── index.ts                 # Plugin entry point (re-exports from src/index.ts)
├── plugin.json              # Plugin manifest (id, name, version, etc.)
└── src/
    ├── index.ts            # Main plugin registration and setup
    ├── NeXT.vue            # Main plugin component
    ├── components/         # All Vue components
    │   ├── base/           # BaseComponent.vue and shared utilities
    │   ├── inputs/         # Input components
    │   ├── panels/         # Panel components (Status, Config, Probing)
    │   └── overrides/      # DWC component overrides
    └── locales/
        └── en.json         # English translations

DuetWebControl/
├── src/plugins/
│   ├── NeXT/              # Symlink to NeXT/ui/
│   └── imports.ts         # Auto-generated plugin registry
└── webpack/lib/
    └── auto-imports-plugin.js  # Plugin discovery system (modified for symlinks)
```

## Setting Up Development Environment

### 1. Start the Development Server

The DuetWebControl dev server must be started from the **DWC repository root**.
This MUST be run in a background terminal so it can stay running.

```bash
cd /home/ben/Documents/RRF/DuetWebControl
npm run dev 
```

**Important Notes:**
- Initial compilation takes 50-60 seconds
- The server will probably be available at `http://localhost:8080/` but read the terminal output when compilation completes for the correct URL.
- Hot Module Replacement (HMR) will reload changes automatically

### 2. Wait for Compilation

Monitor the terminal output for something like the following:
```
DONE  Compiled successfully in 56000ms

  App running at:
  - Local:   http://localhost:8080/
```

### 3. Check Server Status if the URL is not accessible

```bash
# Check if the dev server is running
pgrep -af "vue-cli-service serve"

# View terminal output
# (Use the terminal ID from when you started the server)
```

## Accessing the NeXT Plugin

### First Time Setup (Plugin Not Enabled)

When you first open DWC, the "Connect to Machine" modal dialog will appear. **Before connecting**, check if the NeXT menu item exists in the sidebar:

1. Navigate to `http://localhost:8080/`
2. The "Connect to Machine" dialog will appear
3. **Look at the sidebar behind the dialog** - check if "NeXT" appears under the "Control" section
4. **If "NeXT" menu item is NOT visible**:
   - Click **Cancel** to close the connect dialog
   - Go to **Settings → Plugins**
   - Find "NeXT - Next-Gen Extended Tooling" in the plugin list
   - Click **Start** to enable the plugin
   - The "NeXT" menu item will now appear under **Control** in the sidebar
5. **Now connect to the machine**:
   - Click the **Connect** button in the top banner
   - Enter hostname: `<server address>` (port 80 is default)
   - Leave password blank unless configured on the machine
   - Click **Connect**
6. Once connected, click **NeXT** in the sidebar to view the plugin interface

### Subsequent Sessions (Plugin Already Enabled)

If the plugin is already enabled (you can see "NeXT" in the sidebar):

1. Navigate to `http://localhost:8080/`
2. The "Connect to Machine" dialog will appear
3. Enter hostname: `<server address>`
4. Leave password blank unless configured on the machine
5. Click **Connect**
6. Click **NeXT** in the sidebar to view the plugin interface

**Note**: The plugin must be enabled (started) at least once. This setting persists in browser localStorage, so you typically only need to enable it once per browser/profile.

**Warning**: Dialog boxes and other UI elements have animations associated with them. If you execute an action and then instantly take a snapshot, you may find that the snapshot still contains the 
## Development Workflow

### Making Changes

1. Edit files in `/home/ben/Documents/CAD/Millennium Milo/Repos/NeXT/ui/src/`
2. Save the file
3. Webpack will automatically detect changes and rebuild
4. Monitor the background terminal output to check for any errors and confirm the files have updated
4. The browser will hot-reload the updated component

### Common Development Tasks

#### Fixing TypeScript Errors

All NeXT UI code is TypeScript. When you see compilation errors:

1. Check the terminal output for error details
2. Read the RRF Object Model types in `/home/ben/Documents/RRF/DuetWebControl/node_modules/@duet3d/objectmodel/dist/`
3. Fix type errors in the affected files
4. The dev server will automatically recompile

#### Adding New Components

1. Create component in `NeXT/ui/src/components/<category>/`
2. Export from the category's `index.ts`
3. Import in parent component or `src/index.ts`
4. Register with Vue if it's a global component

#### Checking Browser Console

Use Chrome DevTools or similar to check for:
- Runtime errors
- Vue warnings
- Network request failures
- Plugin load errors

### Testing With the CNC Machine

**Default Machine**: The NeXT development machine is typically at `192.168.1.126` on port 80 (the default).

When connected to the machine:
- Full NeXT functionality is available
- Real-time axis positions and machine state
- G-code commands can be sent and tested
- Probing cycles can be executed (use caution!)
- The "Machine Restart Required" banner will disappear once NeXT variables are loaded

### Testing Without a Real Machine (Disconnected Mode)

The UI can also be developed while **disconnected** from a CNC machine:

- Most UI components will render with default/fallback data
- The RRF object model provides mock data when disconnected
- Some features may show "Not Available" or disabled states
- The "Machine Restart Required" banner is expected when disconnected
- This is useful for UI layout and styling work that doesn't require live machine data

## Critical Development Fixes Applied

### 1. Symlink Support in Plugin Discovery

**Problem**: DWC's `auto-imports-plugin.js` used `file.isDirectory()` which returns `false` for symlinks.

**Fix**: Modified `/home/ben/Documents/RRF/DuetWebControl/webpack/lib/auto-imports-plugin.js`:
```javascript
// Check if it's a directory or a symlink pointing to a directory
const pluginPath = `src/plugins/${file.name}`;
const isDir = file.isDirectory() || (file.isSymbolicLink() && fs.statSync(pluginPath).isDirectory());

if (!isDir || fs.existsSync(`${pluginPath}/blacklist`)) {
    continue;
}
```

### 2. Plugin Entry Point

**Problem**: DWC's plugin system expects an `index.js` or `index.ts` at the plugin root.

**Fix**: Created `/home/ben/Documents/CAD/Millennium Milo/Repos/NeXT/ui/index.ts`:
```typescript
/**
 * NeXT Plugin Entry Point (Root Level)
 */
export { default } from './src/index'
```

### 3. BaseComponent.vue Type Fixes

Fixed multiple TypeScript errors related to RRF object model usage:

1. **Visible Axes**: Changed from `settings.displayedAxes` to `axes.filter(axis => axis.visible)`
2. **Workspace Number**: Changed from `move.currentWorkplace` to `move.workplaceNumber`
3. **Position Calculation**: Simplified to use `axis.userPosition` (already includes offsets)
4. **GPIO Outputs**: Returns default array since `sensors.gpOut` doesn't exist in object model
5. **Type Indexing**: Changed return type to `{[key: string]: Axis}` for flexibility

## Troubleshooting

### Plugin Not Appearing in Plugins List

1. Check if symlink exists: `ls -la /home/ben/Documents/RRF/DuetWebControl/src/plugins/NeXT`
2. Verify `imports.ts` includes NeXT: `grep -A5 "NeXT" /home/ben/Documents/RRF/DuetWebControl/src/plugins/imports.ts`
3. Restart dev server if needed

### Compilation Errors

1. Check terminal output for specific error messages
2. Verify all imports are correct
3. Check TypeScript types match RRF object model
4. Ensure all required dependencies are installed

### Plugin Won't Start

1. Check browser console for JavaScript errors
2. Verify `plugin.json` is valid JSON
3. Check that `src/index.ts` exports a Vue component as default
4. Look for missing dependencies or incorrect imports

### Hot Reload Not Working

1. Ensure dev server is still running: `pgrep -af vue-cli-service`
2. Check for compilation errors in terminal
3. Try a hard refresh in browser (Ctrl+Shift+R)
4. Restart dev server if necessary

### Can't Access NeXT Menu Item

1. Plugin must be **started** via Settings → Plugins first
2. Check that route is registered: Open browser console and run:
   ```javascript
   document.querySelector('#app').__vue__.$router.options.routes.map(r => r.path)
   ```
3. Look for `/NeXT` in the routes list

## Best Practices

### Code Style
- Follow the existing code style in `docs/CODE.md`
- Use TypeScript types from `@duet3d/objectmodel`
- Prefix all global variables with `nxt*`
- Use computed properties over methods where possible

### Component Organization
- Keep components small and focused
- Use `BaseComponent.vue` for shared functionality
- Override DWC components only when necessary
- Document complex logic with comments

### Testing Strategy
- Test UI states while disconnected
- Use `echo` statements for debugging in G-code macros
- Test with DWC in both light and dark themes
- Verify responsive layout at different screen sizes

### Performance
- Avoid expensive computed properties
- Use `v-show` instead of `v-if` for frequently toggled elements
- Lazy-load heavy components when possible
- Monitor Vue DevTools for component re-renders

## Stopping the Development Server

```bash
# Find the process
pgrep -af "vue-cli-service serve"

# Kill it
pkill -f "npm run dev"
```

## Additional Resources

- **RRF Object Model Docs**: https://github.com/Duet3D/RepRapFirmware/wiki/Object-Model-Documentation
- **DWC Plugin Development**: Check `/home/ben/Documents/RRF/DuetWebControl/src/plugins/` for examples
- **Vue 2.7 Docs**: https://v2.vuejs.org/
- **Vuetify 2.x Docs**: https://v2.vuetifyjs.com/

## Quick Reference Commands

```bash
# Start dev server (from DWC directory)
cd /home/ben/Documents/RRF/DuetWebControl && npm run dev 

# Check dev server status
pgrep -af "vue-cli-service serve"

# Stop dev server
pkill -f "npm run dev"

# View plugin imports
cat /home/ben/Documents/RRF/DuetWebControl/src/plugins/imports.ts | grep -A7 NeXT

# Check compilation errors
# (Monitor the terminal where npm run dev is running)

# Edit NeXT UI source
cd /home/ben/Documents/CAD/Millennium\ Milo/Repos/NeXT/ui/src/
```

## Summary

To start developing the NeXT UI:

1. `cd /home/ben/Documents/RRF/DuetWebControl && npm run dev`
2. Wait ~60 seconds for compilation
3. Open `http://localhost:8080/` in browser
4. **First time only**: If "NeXT" not in sidebar, cancel connect dialog → Settings → Plugins → Start "NeXT"
5. Connect to machine at `<server address>` (or work disconnected)
6. Click "NeXT" in sidebar to view plugin
7. Edit files in `NeXT/ui/src/` and see changes hot-reload

The symlinked structure allows you to work directly on the NeXT repository files while testing in the DWC environment.
