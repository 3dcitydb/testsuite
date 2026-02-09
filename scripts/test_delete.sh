#!/bin/bash
set -e

source /scripts/test_helpers.sh

CONFIG_IMPORT="/config/config_citygml_import.json"
INPUT_FILE="/data/synthetic/minimal_building.gml"

echo "=== Delete and Terminate Tests ==="
echo "-------------------------------------------"

# --- Test 1: Delete mode ---
echo "--- Test: Delete features ---"
truncate_features

echo "Importing building for delete test..."
citydb --config $CONFIG_IMPORT import citygml $INPUT_FILE
echo "Import complete."

COUNT_BEFORE=$(get_feature_count)
assert_gt 0 "$COUNT_BEFORE" "Delete test: features exist before delete"

echo "Deleting all features via citydb-tool..."
citydb delete --db-host=db --db-name=citydb --db-username=citydb --db-password=test \
  --delete-mode=delete
echo "Delete command finished."

COUNT_AFTER=$(get_feature_count)
assert_equals "0" "$COUNT_AFTER" "Delete test: all features removed"

# --- Test 2: Terminate mode ---
echo ""
echo "--- Test: Terminate features ---"
truncate_features

echo "Importing building for terminate test..."
citydb --config $CONFIG_IMPORT import citygml $INPUT_FILE
echo "Import complete."

COUNT_BEFORE=$(get_feature_count)
assert_gt 0 "$COUNT_BEFORE" "Terminate test: features exist before terminate"

echo "Terminating all features via citydb-tool..."
citydb delete --db-host=db --db-name=citydb --db-username=citydb --db-password=test \
  --delete-mode=terminate
echo "Terminate command finished."

# After termination, features still exist but should have a termination_date set
COUNT_STILL=$(get_feature_count)
assert_gt 0 "$COUNT_STILL" "Terminate test: features still exist after terminate"

TERM_COUNT=$(db_query "SELECT count(*) FROM feature WHERE termination_date IS NOT NULL;")
assert_gt 0 "$TERM_COUNT" "Terminate test: features have termination_date set"

echo ""
echo "=== Delete and Terminate Tests PASSED ==="
