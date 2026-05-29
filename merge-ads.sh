#!/bin/bash

# Configuration
STATIC_DIR="static"
OUTPUT_FILE="$STATIC_DIR/app-ads.txt"
TEMP_DIR="temp_ads"

# Local Sources (Already in your repo)
APPODEAL_LOCAL="$STATIC_DIR/app_ads_txt.txt"
YANDEX_LOCAL="$STATIC_DIR/app-ads ya ru.txt"

# Public Remote Source
CAS_URL="https://cas.ai/app-ads.txt"

mkdir -p "$TEMP_DIR"

echo "Fetching Clever Ads Solutions (CAS)..."
curl -s -L "$CAS_URL" > "$TEMP_DIR/cas.txt"

# Validation: Ensure the CAS file is actually plain text and not HTML
if grep -q "<!doctype html>" "$TEMP_DIR/cas.txt" || grep -q "<html>" "$TEMP_DIR/cas.txt"; then
    echo "Error: CAS download returned HTML instead of plain text. Using empty fallback."
    echo "" > "$TEMP_DIR/cas.txt"
fi

# Merge Logic
echo "# Consolidated app-ads.txt - Generated on $(date)" > "$OUTPUT_FILE"

# Combine local sources if they exist
[ -f "$APPODEAL_LOCAL" ] && echo "# Appodeal Source" >> "$OUTPUT_FILE" && cat "$APPODEAL_LOCAL" >> "$OUTPUT_FILE"
echo -e "\n" >> "$OUTPUT_FILE"

[ -f "$YANDEX_LOCAL" ] && echo "# Yandex Source" >> "$OUTPUT_FILE" && cat "$YANDEX_LOCAL" >> "$OUTPUT_FILE"
echo -e "\n" >> "$OUTPUT_FILE"

# Add the fetched CAS entries
echo "# CAS Source (Fetched $(date))" >> "$OUTPUT_FILE"
cat "$TEMP_DIR/cas.txt" >> "$OUTPUT_FILE"

# Final cleaning: remove empty lines and sort unique (optional)
# Note: Sorting unique might be bad if providers have overlapping entries with different IDs
# but for app-ads.txt it's generally safe and recommended by IAB.
# We'll normalize spaces around commas to ensure true uniqueness.

grep -v "^#" "$OUTPUT_FILE" | grep -v "^$" | sed 's/, /,/g' | sort -u > "$TEMP_DIR/entries.txt"
echo "# Consolidated app-ads.txt - Generated on $(date)" > "$OUTPUT_FILE"
cat "$TEMP_DIR/entries.txt" >> "$OUTPUT_FILE"

# Cleanup
rm -rf "$TEMP_DIR"

echo "Done! Merged file created at $OUTPUT_FILE"
wc -l "$OUTPUT_FILE"
