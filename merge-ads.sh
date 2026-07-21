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

# Function to normalize entries: trim, remove spaces around commas, normalize case
normalize_entry() {
    # Remove leading/trailing whitespace
    local entry=$(echo "$1" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    
    # Skip comments and empty lines
    if [[ "$entry" =~ ^# ]] || [ -z "$entry" ]; then
        echo "$entry"
        return
    fi
    
    # Skip non-standard entries (like OwnerDomain=)
    if [[ "$entry" =~ ^[a-zA-Z]+= ]]; then
        echo "# $entry"
        return
    fi
    
    # Normalize spacing: remove spaces around commas and normalize to lowercase domain
    echo "$entry" | sed 's/[[:space:]]*,[[:space:]]*/,/g' | sed 's/^[a-zA-Z0-9.-]*\./\L&/' 
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
    # Add CAS entries
    if [ -s "$TEMP_DIR/cas.txt" ]; then
        cat "$TEMP_DIR/cas.txt"
    fi
    
    # Add Appodeal entries
    if [ -f "$APPODEAL_LOCAL" ] && [ -s "$APPODEAL_LOCAL" ]; then
        cat "$APPODEAL_LOCAL"
    fi
    
    # Add Yandex entries
    if [ -f "$YANDEX_LOCAL" ] && [ -s "$YANDEX_LOCAL" ]; then
        cat "$YANDEX_LOCAL"
    fi
} > "$TEMP_DIR/combined.txt"

# Process: normalize, separate comments from entries, deduplicate
{
    echo "# Consolidated app-ads.txt"
    echo "# Last Updated: $(date -u +'%Y-%m-%d %H:%M:%S UTC')"
    echo "# Generated from: CAS, Appodeal, Yandex"
    echo ""
    
    # Extract and normalize all entries
    while IFS= read -r line; do
        if [[ -z "$line" || "$line" =~ ^[[:space:]]*$ ]]; then
            continue  # Skip empty lines
        fi
        normalize_entry "$line"
    done < "$TEMP_DIR/combined.txt" > "$TEMP_DIR/normalized.txt"
    
    # Separate comments from entries
    grep "^#" "$TEMP_DIR/normalized.txt" || true
    echo ""
    
    # Get all non-comment, non-empty lines, deduplicate, and sort
    grep -v "^#" "$TEMP_DIR/normalized.txt" | \
    grep -v "^[[:space:]]*$" | \
    sort -u
} > "$OUTPUT_FILE"

# Add summary stats as comments at the end
{
    echo ""
    echo "# ========== Statistics =========="
    ENTRY_COUNT=$(grep -vc "^#\|^[[:space:]]*$" "$OUTPUT_FILE" || echo 0)
    echo "# Total unique entries: $ENTRY_COUNT"
    echo "# Generated: $(date -u +'%Y-%m-%d %H:%M:%S UTC')"
} >> "$OUTPUT_FILE"

# Cleanup temp files
rm -rf "$TEMP_DIR"

echo ""
echo "✓ Done! Deduplicated and normalized file created at $OUTPUT_FILE"
echo "  Total unique entries: $ENTRY_COUNT"
echo "  File size: $(du -h "$OUTPUT_FILE" | cut -f1)"
