#!/bin/bash
# Setup script for LowKeet users
# Downloads and unpacks AI models from GitHub Release

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# IMPORTANT: Update these values for each release
GITHUB_USER="YOUR_GITHUB_USERNAME"  # TODO: Replace with actual username
GITHUB_REPO="LowKeet"
RELEASE_TAG="v1.0.0"  # TODO: Update for each release

RELEASE_URL="https://github.com/${GITHUB_USER}/${GITHUB_REPO}/releases/download/${RELEASE_TAG}"
ARCHIVE_NAME="lowkeet-models"
TEMP_DIR="$PROJECT_DIR/.model-setup-temp"

echo "============================================================================"
echo "LowKeet Model Setup"
echo "============================================================================"
echo ""
echo "This script will download and install AI models (~1.7GB) from GitHub."
echo ""
echo "Models:"
echo "  • Parakeet TDT v2 (English, high accuracy)"
echo "  • Parakeet TDT v3 (Multilingual)"
echo "  • Whisper models"
echo ""

# Check if models already exist
if [ -d "$PROJECT_DIR/BundledModels/parakeet-tdt-0.6b-v2-coreml" ] && \
   [ -d "$PROJECT_DIR/BundledModels/parakeet-tdt-0.6b-v3-coreml" ]; then
    echo "✓ Models already installed!"
    echo ""
    read -p "Re-download and reinstall? (y/n): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Skipping download. Models are ready."
        exit 0
    fi
    echo ""
fi

# Check for required tools
if ! command -v curl &> /dev/null; then
    echo "❌ Error: curl is required but not installed."
    echo "   Install with: brew install curl"
    exit 1
fi

if ! command -v shasum &> /dev/null; then
    echo "❌ Error: shasum is required but not installed."
    exit 1
fi

# Create temp directory
mkdir -p "$TEMP_DIR"
cd "$TEMP_DIR"

echo "Downloading manifest..."
if ! curl -L -f -o MODELS_MANIFEST.txt "$RELEASE_URL/MODELS_MANIFEST.txt" 2>/dev/null; then
    echo "❌ Error: Could not download manifest from:"
    echo "   $RELEASE_URL/MODELS_MANIFEST.txt"
    echo ""
    echo "Please check:"
    echo "  1. Release $RELEASE_TAG exists"
    echo "  2. MODELS_MANIFEST.txt was uploaded"
    echo "  3. GitHub username is correct: $GITHUB_USER"
    exit 1
fi
echo "  ✓ Manifest downloaded"
echo ""

# Parse manifest to get part count
TOTAL_PARTS=$(grep "Total Parts:" MODELS_MANIFEST.txt | awk '{print $3}')
echo "Found $TOTAL_PARTS part(s) to download"
echo ""

# Download checksums
echo "Downloading checksums..."
curl -L -f -o models.sha256 "$RELEASE_URL/models.sha256"
echo "  ✓ Checksums downloaded"
echo ""

# Download model parts
if [ "$TOTAL_PARTS" -gt 1 ]; then
    echo "Downloading model parts..."
    for i in $(seq 1 $TOTAL_PARTS); do
        PART_FILE="${ARCHIVE_NAME}-part$(printf "%02d" $i).zip"
        echo "  Downloading part $i/$TOTAL_PARTS: $PART_FILE"

        if ! curl -L -f -o "$PART_FILE" "$RELEASE_URL/$PART_FILE"; then
            echo "  ❌ Error: Failed to download $PART_FILE"
            exit 1
        fi

        SIZE=$(du -sh "$PART_FILE" | cut -f1)
        echo "    ✓ Downloaded ($SIZE)"
    done
else
    echo "Downloading models..."
    FULL_FILE="${ARCHIVE_NAME}.zip"
    echo "  Downloading: $FULL_FILE"

    if ! curl -L -f -o "$FULL_FILE" "$RELEASE_URL/$FULL_FILE"; then
        echo "  ❌ Error: Failed to download $FULL_FILE"
        exit 1
    fi

    SIZE=$(du -sh "$FULL_FILE" | cut -f1)
    echo "    ✓ Downloaded ($SIZE)"
fi

echo ""
echo "Verifying checksums..."

# Verify all downloaded files
if shasum -c models.sha256 2>/dev/null; then
    echo "  ✓ All checksums verified!"
else
    echo "  ❌ Error: Checksum verification failed!"
    echo "     Downloaded files may be corrupted."
    exit 1
fi

echo ""
echo "Reassembling and unpacking models..."

# Reassemble if partitioned
if [ "$TOTAL_PARTS" -gt 1 ]; then
    echo "  • Reassembling parts..."
    cat ${ARCHIVE_NAME}-part*.zip > ${ARCHIVE_NAME}.zip
    echo "    ✓ Reassembled"
fi

# Unpack
echo "  • Extracting archive..."
unzip -q ${ARCHIVE_NAME}.zip

# Move to correct locations
echo "  • Installing models..."

# Install BundledModels
if [ -d "BundledModels" ]; then
    echo "    - Installing to BundledModels/"
    rm -rf "$PROJECT_DIR/BundledModels"
    mv BundledModels "$PROJECT_DIR/"
fi

# Install LowKeet/Resources/BundledModels if present
if [ -d "LowKeet-Resources-BundledModels" ]; then
    echo "    - Installing to LowKeet/Resources/BundledModels/"
    rm -rf "$PROJECT_DIR/LowKeet/Resources/BundledModels"
    mkdir -p "$PROJECT_DIR/LowKeet/Resources/BundledModels"
    mv LowKeet-Resources-BundledModels/Parakeet "$PROJECT_DIR/LowKeet/Resources/BundledModels/"
fi

echo "    ✓ Models installed"

echo ""
echo "Cleaning up..."
cd "$PROJECT_DIR"
rm -rf "$TEMP_DIR"
echo "  ✓ Temporary files removed"

echo ""
echo "============================================================================"
echo "✅ SUCCESS - Models are ready!"
echo "============================================================================"
echo ""
echo "Installed models:"

if [ -d "$PROJECT_DIR/BundledModels" ]; then
    echo ""
    echo "BundledModels/:"
    ls -lh "$PROJECT_DIR/BundledModels" | grep -v "^total" | awk '{printf "  • %s (%s)\n", $9, $5}'
fi

if [ -d "$PROJECT_DIR/LowKeet/Resources/BundledModels/Parakeet" ]; then
    echo ""
    echo "LowKeet/Resources/BundledModels/Parakeet/:"
    ls -lh "$PROJECT_DIR/LowKeet/Resources/BundledModels/Parakeet" | grep -v "^total" | awk '{printf "  • %s (%s)\n", $9, $5}'
fi

echo ""
echo "============================================================================"
echo "NEXT STEPS:"
echo "============================================================================"
echo ""
echo "1. Open the project:"
echo "   open LowKeet.xcodeproj"
echo ""
echo "2. Configure code signing:"
echo "   • Select LowKeet project → LowKeet target"
echo "   • Go to 'Signing & Capabilities'"
echo "   • Change 'Team' to your Apple Developer account"
echo ""
echo "3. Build the app:"
echo "   • Press ⌘+B to build"
echo "   • Press ⌘+R to run"
echo ""
echo "✨ You're all set!"
echo ""
