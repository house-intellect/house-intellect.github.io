#!/bin/bash

set -e  # Exit on error

# Configuration
STATIC_DIR="static"
OUTPUT_FILE="$STATIC_DIR/app-ads.txt"
TEMP_DIR="temp_ads"

# Local Sources (Already in your repo)
APPODEAL_LOCAL="$STATIC_DIR/app_ads_txt.txt"
YANDEX_LOCAL="$STATIC_DIR/app-ads ya ru.txt"

# Public Remote Sources
CAS_URL="https://cas.ai/app-ads.txt"

# Create temp directory
mkdir -p "$TEMP_DIR"

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

# Function to ensure file ends with newline
ensure_newline() {
    local file="$1"
    if [ -s "$file" ] && [ "$(tail -c 1 "$file" | wc -l)" -eq 0 ]; then
        echo "" >> "$file"
    fi
}

# Ensure all source files end with newline before combining
ensure_newline "$TEMP_DIR/cas.txt"
if [ -f "$APPODEAL_LOCAL" ] && [ -s "$APPODEAL_LOCAL" ]; then
    ensure_newline "$APPODEAL_LOCAL"
fi
if [ -f "$YANDEX_LOCAL" ] && [ -s "$YANDEX_LOCAL" ]; then
    ensure_newline "$YANDEX_LOCAL"
fi

# Combine all sources WITHOUT any normalization - preserve exactly as they are
echo "Merging sources..."
{
    echo "# Consolidated app-ads.txt"
    echo "# Last Updated: $(date -u +'%Y-%m-%d %H:%M:%S UTC')"
    echo "# Generated from: CAS, Appodeal, Yandex"
    echo "# NOTE: Content from each provider is preserved exactly as-is without any modifications"
    echo ""
    
    if [ -s "$TEMP_DIR/cas.txt" ]; then
        echo "# ========== CAS (Clever Ads Solutions) =========="
        cat "$TEMP_DIR/cas.txt"
    fi
    
    if [ -f "$APPODEAL_LOCAL" ] && [ -s "$APPODEAL_LOCAL" ]; then
        echo "# ========== Appodeal =========="
        cat "$APPODEAL_LOCAL"
    fi
    
    if [ -f "$YANDEX_LOCAL" ] && [ -s "$YANDEX_LOCAL" ]; then
        echo "# ========== Yandex =========="
        cat "$YANDEX_LOCAL"
    fi
    
    echo ""
    echo "# ========== Statistics =========="
    ENTRY_COUNT=$(grep -vc "^#\|^[[:space:]]*$" "$TEMP_DIR/combined.txt" 2>/dev/null || echo 0)
    echo "# Total entries: $ENTRY_COUNT"
    echo "# Generated: $(date -u +'%Y-%m-%d %H:%M:%S UTC')"
} > "$OUTPUT_FILE"

# Ensure file ends with newline
ensure_newline "$OUTPUT_FILE"

# Cleanup temp files
rm -rf "$TEMP_DIR"

echo ""
echo "✓ Done! Merged file created with all provider content preserved as-is"
echo "  File size: $(du -h "$OUTPUT_FILE" | cut -f1)"
