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

# Function to clean and deduplicate content
deduplicate_content() {
    local input_file="$1"
    local output_file="$2"
    
    # Process: remove blank lines, trim whitespace, sort, and remove duplicates
    sed '/^[[:space:]]*$/d' "$input_file" | \
    sed 's/[[:space:]]*$//' | \
    sort | \
    uniq > "$output_file"
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

# Combine all sources into a temporary file
echo "Merging and deduplicating sources..."

{
    echo "# Consolidated app-ads.txt - Generated on $(date)"
    echo "# Last Updated: $(date -u +'%Y-%m-%d %H:%M:%S UTC')"
    echo ""
    
    # Add CAS entries
    if [ -s "$TEMP_DIR/cas.txt" ]; then
        echo "# ========== CAS Source =========="
        cat "$TEMP_DIR/cas.txt"
        echo ""
    fi
    
    # Add Appodeal entries
    if [ -f "$APPODEAL_LOCAL" ] && [ -s "$APPODEAL_LOCAL" ]; then
        echo "# ========== Appodeal Source =========="
        cat "$APPODEAL_LOCAL"
        echo ""
    fi
    
    # Add Yandex entries
    if [ -f "$YANDEX_LOCAL" ] && [ -s "$YANDEX_LOCAL" ]; then
        echo "# ========== Yandex Source =========="
        cat "$YANDEX_LOCAL"
        echo ""
    fi
} > "$TEMP_DIR/combined.txt"

# Separate comments and entries, then deduplicate
{
    # Keep header comments
    grep "^#" "$TEMP_DIR/combined.txt" | head -5
    echo ""
    
    # Get all non-comment, non-empty lines, deduplicate, and sort
    grep -v "^#" "$TEMP_DIR/combined.txt" | \
    grep -v "^[[:space:]]*$" | \
    sed 's/[[:space:]]*$//' | \
    sort | \
    uniq
} > "$OUTPUT_FILE"

# Add summary stats as comments at the end
{
    echo ""
    echo "# ========== Statistics =========="
    echo "# Generated: $(date -u +'%Y-%m-%d %H:%M:%S UTC')"
    echo "# Total entries: $(grep -vc "^#\|^[[:space:]]*$" "$OUTPUT_FILE" || echo 0)"
} >> "$OUTPUT_FILE"

# Cleanup temp files
rm -rf "$TEMP_DIR"

echo ""
echo "✓ Done! Deduplicated file created at $OUTPUT_FILE"
echo "  Total entries: $(grep -vc "^#\|^[[:space:]]*$" "$OUTPUT_FILE" || echo 0)"
echo "  File size: $(du -h "$OUTPUT_FILE" | cut -f1)"
