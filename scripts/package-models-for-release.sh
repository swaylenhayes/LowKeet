#!/bin/bash
# Package models into partitioned zip files for GitHub release
# Run this script ONCE when creating a new release

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
OUTPUT_DIR="$PROJECT_DIR/release-assets"
PART_SIZE_MB=95  # 95MB per part (leaves room for compression overhead)

echo "============================================================================"
echo "LowKeet Model Packaging Script"
echo "============================================================================"
echo ""
echo "This script packages AI models into partitioned zip files for distribution."
echo ""

# Clean previous output
if [ -d "$OUTPUT_DIR" ]; then
    echo "⚠️  Output directory exists: $OUTPUT_DIR"
    read -p "Delete and recreate? (y/n): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf "$OUTPUT_DIR"
        echo "   Deleted."
    else
        echo "   Cancelled."
        exit 1
    fi
fi

mkdir -p "$OUTPUT_DIR"
echo "✓ Created output directory: $OUTPUT_DIR"
echo ""

# Create temporary staging directory
TEMP_DIR=$(mktemp -d)
echo "Using temporary directory: $TEMP_DIR"
echo ""

# Copy models to staging
echo "Copying models to staging area..."
echo ""

# Copy BundledModels (Parakeet v2, v3, Whisper bins)
if [ -d "$PROJECT_DIR/BundledModels" ]; then
    echo "  • BundledModels/ (Parakeet models + Whisper bins)"
    cp -R "$PROJECT_DIR/BundledModels" "$TEMP_DIR/"

    # Show sizes
    if [ -d "$TEMP_DIR/BundledModels/parakeet-tdt-0.6b-v2-coreml" ]; then
        SIZE=$(du -sh "$TEMP_DIR/BundledModels/parakeet-tdt-0.6b-v2-coreml" | cut -f1)
        echo "    - parakeet-tdt-0.6b-v2-coreml: $SIZE"
    fi

    if [ -d "$TEMP_DIR/BundledModels/parakeet-tdt-0.6b-v3-coreml" ]; then
        SIZE=$(du -sh "$TEMP_DIR/BundledModels/parakeet-tdt-0.6b-v3-coreml" | cut -f1)
        echo "    - parakeet-tdt-0.6b-v3-coreml: $SIZE"
    fi

    if [ -f "$TEMP_DIR/BundledModels/ggml-base.en.bin" ]; then
        SIZE=$(du -sh "$TEMP_DIR/BundledModels/ggml-base.en.bin" | cut -f1)
        echo "    - ggml-base.en.bin: $SIZE"
    fi

    if [ -f "$TEMP_DIR/BundledModels/ggml-large-v3-turbo-q5_0.bin" ]; then
        SIZE=$(du -sh "$TEMP_DIR/BundledModels/ggml-large-v3-turbo-q5_0.bin" | cut -f1)
        echo "    - ggml-large-v3-turbo-q5_0.bin: $SIZE"
    fi
fi

# Copy LowKeet/Resources/BundledModels if different
if [ -d "$PROJECT_DIR/LowKeet/Resources/BundledModels/Parakeet" ]; then
    echo "  • LowKeet/Resources/BundledModels/Parakeet/"
    mkdir -p "$TEMP_DIR/LowKeet-Resources-BundledModels"
    cp -R "$PROJECT_DIR/LowKeet/Resources/BundledModels/Parakeet" "$TEMP_DIR/LowKeet-Resources-BundledModels/"

    if [ -d "$TEMP_DIR/LowKeet-Resources-BundledModels/Parakeet/parakeet-tdt-0.6b-v2-coreml" ]; then
        SIZE=$(du -sh "$TEMP_DIR/LowKeet-Resources-BundledModels/Parakeet/parakeet-tdt-0.6b-v2-coreml" | cut -f1)
        echo "    - parakeet-tdt-0.6b-v2-coreml: $SIZE"
    fi

    if [ -d "$TEMP_DIR/LowKeet-Resources-BundledModels/Parakeet/parakeet-tdt-0.6b-v3-coreml" ]; then
        SIZE=$(du -sh "$TEMP_DIR/LowKeet-Resources-BundledModels/Parakeet/parakeet-tdt-0.6b-v3-coreml" | cut -f1)
        echo "    - parakeet-tdt-0.6b-v3-coreml: $SIZE"
    fi
fi

echo ""
TOTAL_SIZE=$(du -sh "$TEMP_DIR" | cut -f1)
echo "Total models size: $TOTAL_SIZE"
echo ""

# Create the archive
echo "Creating archive..."
cd "$TEMP_DIR"
ARCHIVE_NAME="lowkeet-models"

# Create single zip first
echo "  • Creating complete archive..."
zip -r -q "$OUTPUT_DIR/${ARCHIVE_NAME}.zip" ./*
ARCHIVE_SIZE=$(du -sh "$OUTPUT_DIR/${ARCHIVE_NAME}.zip" | cut -f1)
echo "    Complete archive: ${ARCHIVE_NAME}.zip ($ARCHIVE_SIZE)"

# Split into parts if needed
ARCHIVE_SIZE_BYTES=$(stat -f%z "$OUTPUT_DIR/${ARCHIVE_NAME}.zip" 2>/dev/null || stat -c%s "$OUTPUT_DIR/${ARCHIVE_NAME}.zip")
PART_SIZE_BYTES=$((PART_SIZE_MB * 1024 * 1024))

if [ $ARCHIVE_SIZE_BYTES -gt $PART_SIZE_BYTES ]; then
    echo ""
    echo "  • Archive is large, creating ${PART_SIZE_MB}MB parts..."

    # Use split command to partition
    cd "$OUTPUT_DIR"
    split -b ${PART_SIZE_MB}m "${ARCHIVE_NAME}.zip" "${ARCHIVE_NAME}-part"

    # Rename parts to have .zip extension
    PART_NUM=1
    for part in ${ARCHIVE_NAME}-part*; do
        if [ "$part" != "${ARCHIVE_NAME}.zip" ]; then
            mv "$part" "${ARCHIVE_NAME}-part$(printf "%02d" $PART_NUM).zip"
            PART_SIZE=$(du -sh "${ARCHIVE_NAME}-part$(printf "%02d" $PART_NUM).zip" | cut -f1)
            echo "    - ${ARCHIVE_NAME}-part$(printf "%02d" $PART_NUM).zip ($PART_SIZE)"
            PART_NUM=$((PART_NUM + 1))
        fi
    done

    TOTAL_PARTS=$((PART_NUM - 1))
    echo ""
    echo "  ✓ Created $TOTAL_PARTS parts"

    # Keep complete zip for reference, or delete it
    read -p "  Keep complete ${ARCHIVE_NAME}.zip as backup? (y/n): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        rm "$OUTPUT_DIR/${ARCHIVE_NAME}.zip"
        echo "    Deleted complete archive (parts are sufficient)"
    fi
else
    echo "    Archive is small enough, no splitting needed"
    TOTAL_PARTS=1
fi

echo ""

# Generate checksums
echo "Generating checksums..."
cd "$OUTPUT_DIR"
if [ $TOTAL_PARTS -gt 1 ]; then
    shasum -a 256 ${ARCHIVE_NAME}-part*.zip > models.sha256
else
    shasum -a 256 ${ARCHIVE_NAME}.zip > models.sha256
fi
echo "  ✓ Created models.sha256"
echo ""

# Create manifest
cat > "$OUTPUT_DIR/MODELS_MANIFEST.txt" << EOF
LowKeet Models Distribution Package
====================================

Generated: $(date)
Total Parts: $TOTAL_PARTS
Archive Name: $ARCHIVE_NAME

Models Included:
- Parakeet TDT v2 (English, high accuracy)
- Parakeet TDT v3 (Multilingual)
- Whisper base.en model
- Whisper large-v3-turbo model

File List:
EOF

if [ $TOTAL_PARTS -gt 1 ]; then
    for i in $(seq 1 $TOTAL_PARTS); do
        PART_FILE="${ARCHIVE_NAME}-part$(printf "%02d" $i).zip"
        SIZE=$(du -sh "$PART_FILE" | cut -f1)
        echo "  $PART_FILE ($SIZE)" >> "$OUTPUT_DIR/MODELS_MANIFEST.txt"
    done
else
    SIZE=$(du -sh "${ARCHIVE_NAME}.zip" | cut -f1)
    echo "  ${ARCHIVE_NAME}.zip ($SIZE)" >> "$OUTPUT_DIR/MODELS_MANIFEST.txt"
fi

echo "" >> "$OUTPUT_DIR/MODELS_MANIFEST.txt"
echo "Checksums (SHA256):" >> "$OUTPUT_DIR/MODELS_MANIFEST.txt"
cat models.sha256 >> "$OUTPUT_DIR/MODELS_MANIFEST.txt"

echo "  ✓ Created MODELS_MANIFEST.txt"
echo ""

# Cleanup
echo "Cleaning up..."
rm -rf "$TEMP_DIR"
echo "  ✓ Removed temporary directory"
echo ""

# Summary
echo "============================================================================"
echo "✅ SUCCESS - Models packaged for release"
echo "============================================================================"
echo ""
echo "Output directory: $OUTPUT_DIR"
echo ""
echo "Files created:"
ls -lh "$OUTPUT_DIR"
echo ""
echo "============================================================================"
echo "NEXT STEPS:"
echo "============================================================================"
echo ""
echo "1. Create a new GitHub Release (e.g., v1.0.0)"
echo ""
echo "2. Upload ALL files from $OUTPUT_DIR:"
if [ $TOTAL_PARTS -gt 1 ]; then
    echo "   - ${ARCHIVE_NAME}-part01.zip through ${ARCHIVE_NAME}-part$(printf "%02d" $TOTAL_PARTS).zip"
else
    echo "   - ${ARCHIVE_NAME}.zip"
fi
echo "   - models.sha256"
echo "   - MODELS_MANIFEST.txt"
echo ""
echo "3. Users will run: ./scripts/setup-models.sh"
echo "   (This script will download and unpack models automatically)"
echo ""
echo "============================================================================"
