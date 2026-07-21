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

# Function to validate and fix lines
validate_and_fix_line() {
    local line="$1"
    
    # Skip empty lines and comments
    if [[ -z "$line" || "$line" =~ ^[[:space:]]*$ || "$line" =~ ^# ]]; then
        echo "$line"
        return
    fi
    
    # Remove leading/trailing whitespace
    line=$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    
    # Skip non-standard entries
    if [[ "$line" =~ ^[a-zA-Z]+= ]]; then
        return
    fi
    
    # Normalize: remove spaces around commas
    line=$(echo "$line" | sed 's/[[:space:]]*,[[:space:]]*/,/g')
    
    # Check for valid format: domain,id,type[,cert] (3-4 comma-separated fields)
    if [[ "$line" =~ ^[a-zA-Z0-9._-]+,[^,]+,(DIRECT|RESELLER)(,[a-zA-Z0-9]+)?$ ]]; then
        # Convert domain to lowercase for normalization
        local domain=$(echo "$line" | cut -d',' -f1 | tr '[:upper:]' '[:lower:]')
        local rest=$(echo "$line" | cut -d',' -f2-)
        echo "$domain,$rest"
    else
        # Invalid line - skip
        return
    fi
}

# Combine all sources with explicit newlines
echo "Merging sources..."
{
    if [ -s "$TEMP_DIR/cas.txt" ]; then
        cat "$TEMP_DIR/cas.txt"
        echo ""  # Explicit newline separator
    fi
    
    if [ -f "$APPODEAL_LOCAL" ] && [ -s "$APPODEAL_LOCAL" ]; then
        cat "$APPODEAL_LOCAL"
        echo ""  # Explicit newline separator
    fi
    
    if [ -f "$YANDEX_LOCAL" ] && [ -s "$YANDEX_LOCAL" ]; then
        cat "$YANDEX_LOCAL"
        echo ""  # Explicit newline separator
    fi
} > "$TEMP_DIR/combined.txt"

# Process: validate, normalize, deduplicate
echo "Validating and deduplicating..."
{
    echo "# Consolidated app-ads.txt"
    echo "# Last Updated: $(date -u +'%Y-%m-%d %H:%M:%S UTC')"
    echo "# Generated from: CAS, Appodeal, Yandex"
    echo ""
    
    # Process each line
    while IFS= read -r line; do
        validate_and_fix_line "$line"
    done < "$TEMP_DIR/combined.txt" | \
    # Remove empty lines and duplicates, then sort
    grep -v "^[[:space:]]*$" | sort -u
} > "$OUTPUT_FILE"

# Add summary stats and ensure proper ending
{
    echo ""
    echo "# ========== Statistics =========="
    ENTRY_COUNT=$(grep -vc "^#\|^[[:space:]]*$" "$OUTPUT_FILE" || echo 0)
    echo "# Total unique entries: $ENTRY_COUNT"
    echo "# Generated: $(date -u +'%Y-%m-%d %H:%M:%S UTC')"
} >> "$OUTPUT_FILE"

# Ensure file ends with newline
ensure_newline "$OUTPUT_FILE"

# Cleanup temp files
rm -rf "$TEMP_DIR"

echo ""
echo "✓ Done! Validated and deduplicated file created"
echo "  Total unique valid entries: $ENTRY_COUNT"
echo "  File size: $(du -h "$OUTPUT_FILE" | cut -f1)"
