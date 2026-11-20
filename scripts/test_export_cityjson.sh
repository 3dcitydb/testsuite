#!/bin/bash
set -e

source /scripts/test_helpers.sh

CONFIG_FILE="/config/config_cityjson_export.json"
OUTPUT_FILE="/output/exported_building.city.json"

echo "=== CityJSON Export Tests ==="
echo "-------------------------------------------"

# Ensure there is data to export by importing first
truncate_features
echo "Importing synthetic building data for export test..."
citydb import cityjson \
  --db-host=db --db-name=citydb --db-username=citydb --db-password=test \
  /data/synthetic/minimal_building.city.json
echo "Import complete."

COUNT=$(get_feature_count)
assert_gt 0 "$COUNT" "Pre-export: features exist in database"

# Export to CityJSON
echo "Exporting to CityJSON..."
citydb --config $CONFIG_FILE export cityjson -o $OUTPUT_FILE
echo "Export command finished."

# Verify output file exists and has content
assert_file_exists "$OUTPUT_FILE" 100 "CityJSON export: output file exists with content"

echo ""
echo "=== CityJSON Export Tests PASSED ==="
