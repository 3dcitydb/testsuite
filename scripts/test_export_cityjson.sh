#!/bin/bash
set -e

source /scripts/test_helpers.sh

CONFIG_FILE="/config/config_cityjson_export.json"
OUTPUT_FILE="/output/exported_building.city.json"

echo "=== CityJSON Export Tests ==="
echo "-------------------------------------------"

truncate_features
run_quiet citydb import cityjson "${DB_ARGS[@]}" /data/synthetic/minimal_building.city.json
assert_equals 1 "$(get_feature_count_by_type 'Building')" "Pre-export: building imported"

rm -f "$OUTPUT_FILE"
run_quiet citydb --config "$CONFIG_FILE" export cityjson -o "$OUTPUT_FILE"
echo "Export complete."

assert_file_exists "$OUTPUT_FILE" 100 "CityJSON export: output file exists with content"
assert_export_count 1 "$OUTPUT_FILE" Building "CityJSON export: building exported"
assert_schema_valid "$OUTPUT_FILE" "CityJSON export: schema-valid"

echo ""
echo "=== CityJSON Export Tests PASSED ==="
