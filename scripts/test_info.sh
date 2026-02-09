#!/bin/bash
set -e

source /scripts/test_helpers.sh

CONFIG_IMPORT="/config/config_citygml_import.json"
INPUT_FILE="/data/synthetic/minimal_building.gml"

echo "=== Info Command Tests ==="
echo "-------------------------------------------"

# Ensure there is data in the database
truncate_features
echo "Importing test data..."
citydb --config $CONFIG_IMPORT import citygml $INPUT_FILE
echo "Import complete."

COUNT=$(get_feature_count)
assert_gt 0 "$COUNT" "Info test: features exist for info query"

# Run the info command
echo ""
echo "--- Test: Database info ---"
citydb info --db-host=db --db-name=citydb --db-username=citydb --db-password=test
echo "PASS: Info command succeeded"

echo ""
echo "=== Info Command Tests PASSED ==="
