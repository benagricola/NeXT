#!/bin/bash
# Setup script for Chrome and Playwright for MCP server
# This script can be run both locally and in GitHub Actions/Copilot Workspace

set -e

echo "🔧 Setting up Chrome and Playwright for MCP server..."

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo "❌ Node.js is not installed. Please install Node.js 18+ first."
    exit 1
fi

echo "✅ Node.js $(node --version) found"

# Check if npm is installed
if ! command -v npm &> /dev/null; then
    echo "❌ npm is not installed. Please install npm first."
    exit 1
fi

echo "✅ npm $(npm --version) found"

# Install Playwright globally if not already installed
if ! command -v playwright &> /dev/null; then
    echo "📦 Installing Playwright globally..."
    npm install -g playwright
else
    echo "✅ Playwright already installed ($(npx playwright --version))"
fi

# Check if Chrome/Chromium is already installed in the system
CHROME_FOUND=false
for chrome_bin in google-chrome chromium-browser chromium; do
    if command -v $chrome_bin &> /dev/null; then
        CHROME_VERSION=$($chrome_bin --version 2>/dev/null || echo "version unknown")
        echo "✅ Found $chrome_bin: $CHROME_VERSION"
        CHROME_FOUND=true
        break
    fi
done

# Only install Playwright's Chromium if system Chrome is not available
if [ "$CHROME_FOUND" = false ]; then
    echo "🌐 Installing Chromium browser with dependencies..."
    if npx playwright install --with-deps chromium; then
        echo "✅ Chromium browser installed successfully"
    else
        echo "⚠️ Chromium installation failed, trying without --with-deps..."
        if npx playwright install chromium; then
            echo "✅ Chromium browser installed successfully (without system deps)"
        else
            echo "❌ Failed to install Chromium browser"
            echo "⚠️ You may need to run this script again or check your network connection"
            exit 1
        fi
    fi
else
    echo "ℹ️  System Chrome found - skipping Playwright Chromium installation"
    echo "ℹ️  Playwright will use the system Chrome installation"
fi

# Install additional dependencies on Linux (if needed)
if [[ "$OSTYPE" == "linux-gnu"* ]] && [ "$CHROME_FOUND" = false ]; then
    echo "🐧 Detected Linux without system Chrome, installing dependencies..."
    
    # Check if we have sudo access
    if command -v sudo &> /dev/null && sudo -n true 2>/dev/null; then
        sudo apt-get update -qq
        sudo apt-get install -y \
            libnss3 \
            libnspr4 \
            libatk1.0-0 \
            libatk-bridge2.0-0 \
            libcups2 \
            libdrm2 \
            libdbus-1-3 \
            libxkbcommon0 \
            libxcomposite1 \
            libxdamage1 \
            libxfixes3 \
            libxrandr2 \
            libgbm1 \
            libpango-1.0-0 \
            libcairo2 \
            libasound2 \
            2>/dev/null || echo "⚠️ Some dependencies may not have been installed (non-critical)"
    else
        echo "⚠️ No sudo access - skipping system dependencies (may be already installed)"
    fi
fi

echo ""
echo "✅ Chrome and Playwright setup completed successfully!"
echo "✅ MCP server can now use Playwright tools for:"
echo "   - Browser automation"
echo "   - UI testing"
echo "   - Screenshot capture"
echo "   - Web page interaction"
echo ""
echo "📝 To verify the setup, the Playwright MCP server tools are now available:"
echo "   - playwright-browser_navigate"
echo "   - playwright-browser_take_screenshot"
echo "   - playwright-browser_click"
echo "   - and more..."

