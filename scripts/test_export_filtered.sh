#!/bin/bash
set -e

source /scripts/test_helpers.sh

CONFIG_BUILDINGS="$CONFIG_DIR/config_export_buildings.json"
CONFIG_BBOX="$CONFIG_DIR/config_export_bbox.json"
CONFIG_IMPORT="$CONFIG_DIR/config_citygml_import.json"
OUTPUT_BUILDINGS="/output/exported_buildings_only.gml"
OUTPUT_BBOX="/output/exported_bbox.gml"

echo "=== Filtered Export Tests ==="
echo "-------------------------------------------"

# Clear and import mixed data: building + road
truncate_features

echo "Importing building data..."
citydb --config $CONFIG_IMPORT import citygml /data/synthetic/minimal_building.gml
echo "Building import complete."

echo "Importing road data..."
citydb --config $CONFIG_IMPORT import citygml /data/synthetic/minimal_road.gml
echo "Road import complete."

TOTAL=$(get_feature_count)
assert_gt 1 "$TOTAL" "Pre-export: multiple feature types exist"

# Test 1: Export buildings only (feature type filter)
echo ""
echo "--- Test: Export Buildings Only ---"
citydb --config $CONFIG_BUILDINGS export citygml -o $OUTPUT_BUILDINGS
echo "Filtered export command finished."
assert_file_exists "$OUTPUT_BUILDINGS" 100 "Buildings-only export: file exists with content"
assert_equals "1" "$(count_elements "$OUTPUT_BUILDINGS" "bldg:Building")" "Buildings-only export: building exported"
assert_equals "0" "$(count_elements "$OUTPUT_BUILDINGS" "tran:Road")" "Buildings-only export: road filtered out"

# Test 2: Export with bounding box filter (the bbox only overlaps the road, not the building)
echo ""
echo "--- Test: Export with Bounding Box ---"
citydb --config $CONFIG_BBOX export citygml -o $OUTPUT_BBOX
echo "Bbox export command finished."
assert_file_exists "$OUTPUT_BBOX" 100 "Bbox export: file exists with content"
assert_equals "1" "$(count_elements "$OUTPUT_BBOX" "tran:Road")" "Bbox export: road inside bbox exported"
assert_equals "0" "$(count_elements "$OUTPUT_BBOX" "bldg:Building")" "Bbox export: building outside bbox filtered out"

echo ""
echo "=== Filtered Export Tests PASSED ==="
