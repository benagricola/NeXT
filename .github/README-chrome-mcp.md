# Chrome MCP Server Setup

This directory contains configuration and scripts to set up Chrome and Playwright for the MCP (Model Context Protocol) server used by GitHub Copilot agents.

## Overview

The Chrome MCP server enables Copilot agents to:
- Automate browser interactions for testing
- Capture screenshots of UI components
- Test the NeXT Duet Web Control plugin
- Perform visual regression testing
- Interact with web pages programmatically

## Files

- **copilot-setup-steps.yml** - GitHub Actions workflow that ensures Chrome and Playwright are installed when Copilot agents run
- **scripts/setup-chrome-mcp.sh** - Bash script that handles the actual installation and configuration

## How It Works

### Automatic Setup (GitHub Actions/Copilot Workspace)

The workflow (`copilot-setup-steps.yml`) automatically runs when:
1. Manually triggered via `workflow_dispatch`
2. Code is pushed to branches matching `copilot/**`

It will:
1. Check out the repository
2. Set up Node.js 18
3. Run the setup script to install Chrome and Playwright
4. Cache Playwright browsers for faster subsequent runs

### Manual Setup (Local Development)

To set up Chrome and Playwright locally:

```bash
bash .github/scripts/setup-chrome-mcp.sh
```

The script will:
1. Check for Node.js and npm
2. Install Playwright globally if not present
3. Detect if Chrome/Chromium is already installed
4. Install Playwright's Chromium only if system Chrome is not available
5. Install necessary Linux dependencies if needed

## Usage

Once set up, Copilot agents can use Playwright MCP tools:

```javascript
// Navigate to a page
await playwright-browser_navigate({ url: 'http://localhost:8080' });

// Take a screenshot
await playwright-browser_take_screenshot({ 
  filename: 'ui-component.png',
  type: 'png'
});

// Click elements, fill forms, etc.
await playwright-browser_click({ element: 'button', ref: 'e5' });
```

## Testing UI Changes

To test UI changes to the NeXT plugin:

1. Build the plugin (see `docs/UI_DEVELOPMENT.md`)
2. Serve it locally or deploy to a test DWC instance
3. Use the Copilot agent with MCP tools to:
   - Navigate to the interface
   - Take screenshots
   - Test interactions
   - Verify functionality

## Troubleshooting

### Chrome not found
- The script first checks for system Chrome/Chromium
- If not found, it installs Playwright's bundled Chromium
- Ensure you have internet connectivity for downloads

### Playwright installation fails
- Check your network connection
- Ensure Node.js 18+ is installed
- Try running the script again

### Permission errors
- The script needs sudo access to install system dependencies
- If sudo is not available, some dependencies may not install (usually non-critical)

## Requirements

- Node.js 18 or higher
- npm
- Linux (Ubuntu/Debian recommended) or macOS
- Internet connection for initial setup

## Example Output

```
🔧 Setting up Chrome and Playwright for MCP server...
✅ Node.js v20.19.5 found
✅ npm 10.8.2 found
✅ Playwright already installed (Version 1.56.1)
✅ Found google-chrome: Google Chrome 142.0.7444.59 
ℹ️  System Chrome found - skipping Playwright Chromium installation

✅ Chrome and Playwright setup completed successfully!
✅ MCP server can now use Playwright tools for:
   - Browser automation
   - UI testing
   - Screenshot capture
   - Web page interaction
```

## Screenshot Example

![Chrome MCP Test Success](https://github.com/user-attachments/assets/b67e0a1e-a344-4cf8-8a24-2ae01b60218b)

The screenshot above demonstrates the Chrome MCP server successfully rendering a test page and capturing screenshots.
