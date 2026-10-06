#!/bin/bash
set -e

source /scripts/test_helpers.sh

CONFIG_BUILDINGS="/config/config_export_buildings.json"
CONFIG_BBOX="/config/config_export_bbox.json"
CONFIG_IMPORT="/config/config_citygml_import.json"
OUTPUT_BUILDINGS="/output/exported_buildings_only.gml"
OUTPUT_BBOX="/output/exported_bbox.gml"

echo "=== Filtered Export Tests ==="
echo "-------------------------------------------"

# Clear and import mixed data: building + road
truncate_features

run_quiet citydb --config "$CONFIG_IMPORT" import citygml /data/synthetic/minimal_building.gml
run_quiet citydb --config "$CONFIG_IMPORT" import citygml /data/synthetic/minimal_road.gml
echo "Import complete."

assert_equals 1 "$(get_feature_count_by_type 'Building')" "Pre-export: building imported"
assert_equals 1 "$(get_feature_count_by_type 'Road')" "Pre-export: road imported"

# Test 1: Export buildings only (feature type filter)
echo ""
echo "--- Test: Export Buildings Only ---"
rm -f "$OUTPUT_BUILDINGS"
run_quiet citydb --config "$CONFIG_BUILDINGS" export citygml -o "$OUTPUT_BUILDINGS"
assert_file_exists "$OUTPUT_BUILDINGS" 100 "Buildings-only export: file exists with content"
assert_export_count 1 "$OUTPUT_BUILDINGS" "bldg:Building" "Buildings-only export: building exported"
assert_export_count 0 "$OUTPUT_BUILDINGS" "tran:Road" "Buildings-only export: road filtered out"
assert_schema_valid "$OUTPUT_BUILDINGS" "Buildings-only export: schema-valid"

# Test 2: Export with a bounding box filter from the config.  The bbox lies
# east of the building (x > 458890) and covers only the road.
echo ""
echo "--- Test: Export with Bounding Box ---"
rm -f "$OUTPUT_BBOX"
run_quiet citydb --config "$CONFIG_BBOX" export citygml -o "$OUTPUT_BBOX"
assert_export_ids "ROAD_TEST_001" "$OUTPUT_BBOX" "bldg:Building,tran:Road" "Bbox export: only the road intersects the bbox"
assert_schema_valid "$OUTPUT_BBOX" "Bbox export: schema-valid"

echo ""
echo "=== Filtered Export Tests PASSED ==="
