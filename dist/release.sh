#!/usr/bin/env bash
WD="${PWD}"
TMP_DIR=$(mktemp -d -t next-release-XXXXX)
ZIP_NAME="${1:-next-sd-release}.zip"
ZIP_PATH="${WD}/dist/${ZIP_NAME}"
SYNC_CMD="rsync -a --exclude=README.md --exclude='*.gitkeep'"
COMMIT_ID=$(git describe --tags --exclude "release-*" --always --dirty)
DWC_REPO_PATH="${2:-${WD}/DuetWebControl}"

echo "Building NeXT release ${ZIP_NAME} for ${COMMIT_ID}..."

# Make stub folder-structure
mkdir -p "${TMP_DIR}/sd/sys"

# Copy all macros to sys/ for system functionality (G/M-codes)
${SYNC_CMD} macros/system/* macros/probing/* macros/tooling/* macros/spindle/* macros/coolant/* macros/utilities/* "${TMP_DIR}/sd/sys/"

[[ -f "${ZIP_PATH}" ]] && rm "${ZIP_PATH}"

cd "${TMP_DIR}"

echo "Replacing %%NXT_VERSION%% with ${COMMIT_ID}..."
sed -si -e "s/%%NXT_VERSION%%/${COMMIT_ID}/g" sd/sys/nxt.g

# Conditionally build and include the UI if it exists
if [[ -f "${WD}/ui/plugin.json" ]]; then
    echo "UI directory found, building plugin..."

    if [[ ! -d "${DWC_REPO_PATH}" ]]; then
        echo "Duet Web Control repository not found at ${DWC_REPO_PATH}"
        exit 1
    fi

    # Copy UI source for build
    cp -r "${WD}/ui/"* "${TMP_DIR}/"
    sed -si -e "s/%%NXT_VERSION%%/${COMMIT_ID}/g" plugin.json

    # Build the DWC Plugin
    (   cd "${DWC_REPO_PATH}"
        npm install
        npm run build-plugin "${TMP_DIR}" || exit 1
        # Copy the built plugin to the main dist folder
        cp dist/NeXT-${COMMIT_ID}.zip "${WD}/dist/" || exit 1
    ) || exit 1

    # Extract the "dwc" folder from the plugin into the SD directory
    unzip -o "${WD}/dist/NeXT-${COMMIT_ID}.zip" "dwc/*" -d "${TMP_DIR}/sd"
    
    # Generate dwc-plugins.json automatically
    echo "Generating dwc-plugins.json..."
    
    # Extract DWC file paths from the plugin ZIP
    DWC_FILES=$(unzip -l "${WD}/dist/NeXT-${COMMIT_ID}.zip" | grep -E '^\s+[0-9]+.*dwc/' | awk '{print $4}' | sed 's|dwc/||' | sort | jq -R . | jq -s .)
    
    # Extract SD file paths (macro files that go in sys/)
    SD_FILES=$(find "${TMP_DIR}/sd/sys" -type f -name "*.g" | sed "s|${TMP_DIR}/sd/||" | sort | jq -R . | jq -s .)
    
    # Create the dwc-plugins.json file using jq to properly handle JSON
    jq -n \
      --arg id "NeXT" \
      --arg name "NeXT - Next-Gen Extended Tooling" \
      --arg author "NeXT Development Team" \
      --arg version "${COMMIT_ID}" \
      --arg license "GPL-3.0-or-later" \
      --arg homepage "https://github.com/benagricola/NeXT" \
      --argjson dwcFiles "${DWC_FILES}" \
      --argjson sdFiles "${SD_FILES}" \
      '{
        "NeXT": {
          "id": $id,
          "name": $name,
          "author": $author,
          "version": $version,
          "license": $license,
          "homepage": $homepage,
          "tags": [],
          "dwcVersion": "auto",
          "dwcDependencies": [],
          "sbcRequired": false,
          "sbcDsfVersion": null,
          "sbcExecutable": null,
          "sbcExecutableArguments": null,
          "sbcExtraExecutables": [],
          "sbcAutoRestart": false,
          "sbcOutputRedirected": true,
          "sbcPermissions": [],
          "sbcConfigFiles": [],
          "sbcPackageDependencies": [],
          "sbcPluginDependencies": [],
          "sbcPythonDependencies": [],
          "rrfVersion": "auto",
          "data": {},
          "dsfFiles": [],
          "dwcFiles": $dwcFiles,
          "sdFiles": $sdFiles,
          "pid": -1
        }
      }' > "${TMP_DIR}/sd/sys/dwc-plugins.json"
fi

# Create the final SD card release ZIP
# Ensure output directory exists
mkdir -p "$(dirname "${ZIP_PATH}")"
(
    cd "${TMP_DIR}/sd"
    zip -r "${ZIP_PATH}" * -x "*.gitkeep"
) || exit 1

cd "${WD}"
rm -rf "${TMP_DIR}"

echo "NeXT release created at ${ZIP_PATH}"