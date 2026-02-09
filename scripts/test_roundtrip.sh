#!/bin/bash
set -e

source /scripts/test_helpers.sh

CONFIG_IMPORT="/config/config_citygml_import.json"
CONFIG_EXPORT="/config/config_citygml_export.json"
INPUT_FILE="/data/synthetic/minimal_building.gml"
OUTPUT_FILE="/output/roundtrip_export.gml"

echo "=== Roundtrip Tests ==="
echo "-------------------------------------------"

# Step 1: Clear and import
truncate_features

echo "Step 1: Importing original data..."
citydb --config $CONFIG_IMPORT import citygml $INPUT_FILE
echo "Import complete."

COUNT_ORIGINAL=$(get_feature_count)
assert_gt 0 "$COUNT_ORIGINAL" "Roundtrip: original import has features"
echo "Original feature count: $COUNT_ORIGINAL"

# Step 2: Export
echo ""
echo "Step 2: Exporting data..."
citydb --config $CONFIG_EXPORT export citygml -o $OUTPUT_FILE
echo "Export complete."
assert_file_exists "$OUTPUT_FILE" 100 "Roundtrip: export file created"

# Step 3: Clear database
echo ""
echo "Step 3: Clearing database..."
truncate_features
COUNT_CLEARED=$(get_feature_count)
assert_equals "0" "$COUNT_CLEARED" "Roundtrip: database cleared"

# Step 4: Re-import from exported file
echo ""
echo "Step 4: Re-importing exported data..."
citydb --config $CONFIG_IMPORT import citygml $OUTPUT_FILE
echo "Re-import complete."

COUNT_REIMPORT=$(get_feature_count)
assert_gt 0 "$COUNT_REIMPORT" "Roundtrip: reimport has features"
echo "Re-imported feature count: $COUNT_REIMPORT"

# Step 5: Compare counts
echo ""
echo "Step 5: Comparing feature counts..."
assert_equals "$COUNT_ORIGINAL" "$COUNT_REIMPORT" "Roundtrip: feature count matches after reimport"

echo ""
echo "=== Roundtrip Tests PASSED ==="
