#!/bin/bash

# LowKeet Dependency Installer
# Automatically downloads AI models and Whisper framework from GitHub releases

set -e  # Exit on error

REPO="swaylenhayes/lowkeet"
MODELS_VERSION="models-v1.0"
FRAMEWORK_VERSION="whisper-framework-v1.0"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "🚀 LowKeet Dependency Installer"
echo "================================"
echo ""

# Check if we're in the right directory
if [ ! -f "LowKeet.xcodeproj/project.pbxproj" ]; then
    echo -e "${RED}Error: Must be run from the LowKeet project root directory${NC}"
    echo "Usage: cd /path/to/LowKeet && ./scripts/install-dependencies.sh"
    exit 1
fi

# Check if gh CLI is available
if ! command -v gh &> /dev/null; then
    echo -e "${YELLOW}Warning: GitHub CLI (gh) not found${NC}"
    echo "Install it with: brew install gh"
    echo ""
    echo "Alternatively, download dependencies manually from:"
    echo "  - https://github.com/$REPO/releases/tag/$MODELS_VERSION"
    echo "  - https://github.com/$REPO/releases/tag/$FRAMEWORK_VERSION"
    exit 1
fi

# Function to download and extract a release
download_release() {
    local tag=$1
    local description=$2
    local target_check=$3

    if [ -d "$target_check" ]; then
        echo -e "${GREEN}✓${NC} $description already installed"
        return 0
    fi

    echo -e "${YELLOW}⬇${NC}  Downloading $description..."

    # Create temp directory
    local temp_dir=$(mktemp -d)
    cd "$temp_dir"

    # Download release assets
    if ! gh release download "$tag" -R "$REPO" 2>/dev/null; then
        echo -e "${RED}✗${NC} Failed to download $description"
        echo "   Release tag: $tag"
        rm -rf "$temp_dir"
        return 1
    fi

    # Check if we have a zip file or parts
    if ls *.zip.part* 1> /dev/null 2>&1; then
        echo "  Reassembling multi-part archive..."
        cat *.zip.part* > combined.zip
        unzip -q combined.zip
    elif ls *.zip 1> /dev/null 2>&1; then
        echo "  Extracting archive..."
        unzip -q *.zip
    else
        echo -e "${RED}✗${NC} No archive found in release"
        rm -rf "$temp_dir"
        return 1
    fi

    # Move extracted content to project root
    cd "$OLDPWD"

    if [ -d "$temp_dir/BundledModels" ]; then
        mv "$temp_dir/BundledModels" ./
        echo -e "${GREEN}✓${NC} $description installed successfully"
    elif [ -d "$temp_dir/whisper.xcframework" ]; then
        mv "$temp_dir/whisper.xcframework" ./
        echo -e "${GREEN}✓${NC} $description installed successfully"
    else
        echo -e "${RED}✗${NC} Expected content not found in archive"
        rm -rf "$temp_dir"
        return 1
    fi

    # Cleanup
    rm -rf "$temp_dir"
    return 0
}

# Download AI Models
echo ""
echo "📦 Checking AI Models..."
download_release "$MODELS_VERSION" "AI Models (1.6 GB)" "BundledModels"

# Download Whisper Framework
echo ""
echo "🔧 Checking Whisper Framework..."
download_release "$FRAMEWORK_VERSION" "Whisper.cpp Framework (161 MB)" "whisper.xcframework"

echo ""
echo -e "${GREEN}✅ All dependencies installed!${NC}"
echo ""
echo "Next steps:"
echo "  1. Open LowKeet.xcodeproj in Xcode"
echo "  2. Select your developer account in Signing & Capabilities"
echo "  3. Press Cmd+R to build and run"
echo ""
echo "Happy transcribing! 🎙️"
