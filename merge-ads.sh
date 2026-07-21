#!/bin/bash

set -e  # Exit on error

# Configuration
STATIC_DIR="static"
OUTPUT_FILE="$STATIC_DIR/app-ads.txt"
TEMP_DIR="temp_ads"

# Local Sources (Already in your repo)
APPODEAL_LOCAL="$STATIC_DIR/app_ads_txt.txt"
YANDEX_LOCAL="$STATIC_DIR/app-ads ya ru.txt"

# Public Remote Source
CAS_URL="https://cas.ai/app-ads.txt"

# Create temp directory
mkdir -p "$TEMP_DIR"

# Function to clean content (remove empty lines and trim)
clean_content() {
    sed '/^[[:space:]]*$/d' "$1" | sed 's/[[:space:]]*$//'
}

echo "Fetching Clever Ads Solutions (CAS)..."
if curl -s -L --max-time 30 --retry 3 "$CAS_URL" > "$TEMP_DIR/cas.txt"; then
    echo "✓ CAS fetched successfully"
else
    echo "⚠ Failed to fetch CAS, using empty fallback"
    echo "" > "$TEMP_DIR/cas.txt"
fi

# Validation: Ensure the CAS file is actual content and not HTML error page
if [ -s "$TEMP_DIR/cas.txt" ] && (grep -qi "<!doctype\|<html\|<body" "$TEMP_DIR/cas.txt" || [ "$(wc -c < "$TEMP_DIR/cas.txt")" -lt 10 ]); then
    echo "⚠ CAS returned HTML or invalid content. Using empty fallback."
    echo "" > "$TEMP_DIR/cas.txt"
fi

# Start building the consolidated file
echo "# Consolidated app-ads.txt - Generated on $(date)" > "$OUTPUT_FILE"
echo "# Last Updated: $(date -u +'%Y-%m-%d %H:%M:%S UTC')" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# Add CAS entries
if [ -s "$TEMP_DIR/cas.txt" ]; then
    echo "# ========== CAS Source ==========" >> "$OUTPUT_FILE"
    clean_content "$TEMP_DIR/cas.txt" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
fi

# Add Appodeal entries
if [ -f "$APPODEAL_LOCAL" ] && [ -s "$APPODEAL_LOCAL" ]; then
    echo "# ========== Appodeal Source ==========" >> "$OUTPUT_FILE"
    clean_content "$APPODEAL_LOCAL" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
fi

# Add Yandex entries
if [ -f "$YANDEX_LOCAL" ] && [ -s "$YANDEX_LOCAL" ]; then
    echo "# ========== Yandex Source ==========" >> "$OUTPUT_FILE"
    clean_content "$YANDEX_LOCAL" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
fi

# Final cleanup - remove trailing blank lines
sed -i -e :a -e '/^\s*$/d;N;ba' "$OUTPUT_FILE" || true

# Cleanup temp files
rm -rf "$TEMP_DIR"

echo ""
echo "✓ Done! Merged file created at $OUTPUT_FILE"
echo "  Total lines: $(wc -l < "$OUTPUT_FILE")"
echo "  File size: $(du -h "$OUTPUT_FILE" | cut -f1)"
