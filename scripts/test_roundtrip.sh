#!/bin/bash
set -e

source /scripts/test_helpers.sh

CONFIG_IMPORT="/config/config_citygml_import.json"
CONFIG_EXPORT="/config/config_citygml_export.json"
INPUT_FILE=$(resolve_citygml_input "/data/synthetic/minimal_building.gml")
OUTPUT_FILE="/output/roundtrip_export.gml"

echo "=== Round-Trip Tests ==="
echo "-------------------------------------------"

# Step 1: Clear and import
truncate_features

echo "Step 1: Importing original data..."
run_quiet citydb --config "$CONFIG_IMPORT" import citygml "$INPUT_FILE"
echo "Import complete."

COUNT_ORIGINAL=$(get_feature_count)
assert_gt 0 "$COUNT_ORIGINAL" "Round trip: original import has features"
echo "Original feature count: $COUNT_ORIGINAL"

# Step 2: Export
echo ""
echo "Step 2: Exporting data..."
rm -f "$OUTPUT_FILE"
run_quiet citydb --config "$CONFIG_EXPORT" export citygml -o "$OUTPUT_FILE"
echo "Export complete."
assert_file_exists "$OUTPUT_FILE" 100 "Round trip: export file created"

# Step 3: Clear database
echo ""
echo "Step 3: Clearing database..."
truncate_features
COUNT_CLEARED=$(get_feature_count)
assert_equals "0" "$COUNT_CLEARED" "Round trip: database cleared"

# Step 4: Re-import from exported file
echo ""
echo "Step 4: Re-importing exported data..."
run_quiet citydb --config "$CONFIG_IMPORT" import citygml "$OUTPUT_FILE"
echo "Re-import complete."

COUNT_REIMPORT=$(get_feature_count)
assert_gt 0 "$COUNT_REIMPORT" "Round trip: reimport has features"
echo "Re-imported feature count: $COUNT_REIMPORT"

# Step 5: Compare counts
echo ""
echo "Step 5: Comparing feature counts..."
assert_equals "$COUNT_ORIGINAL" "$COUNT_REIMPORT" "Round trip: feature count matches after reimport"

echo ""
echo "=== Round-Trip Tests PASSED ==="
