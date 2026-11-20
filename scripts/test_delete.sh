#!/bin/bash
set -e

source /scripts/test_helpers.sh

CONFIG_IMPORT="/config/config_citygml_import.json"
INPUT_FILE=$(resolve_citygml_input "/data/synthetic/minimal_building.gml")

echo "=== Delete and Terminate Tests ==="
echo "-------------------------------------------"

# --- Test 1: Delete mode ---
echo "--- Test: Delete features ---"
truncate_features
run_quiet citydb --config "$CONFIG_IMPORT" import citygml "$INPUT_FILE"
assert_gt 0 "$(get_feature_count)" "Delete test: features exist before delete"

run_quiet citydb delete "${DB_ARGS[@]}" --delete-mode=delete
assert_equals 0 "$(get_feature_count)" "Delete test: all features removed"

# --- Test 2: Terminate mode ---
echo ""
echo "--- Test: Terminate features ---"
truncate_features
run_quiet citydb --config "$CONFIG_IMPORT" import citygml "$INPUT_FILE"
COUNT_BEFORE=$(get_feature_count)
assert_gt 0 "$COUNT_BEFORE" "Terminate test: features exist before terminate"

run_quiet citydb delete "${DB_ARGS[@]}" --delete-mode=terminate

# Terminated features stay in the database with a termination_date.
assert_equals "$COUNT_BEFORE" "$(get_feature_count)" "Terminate test: features are kept"
assert_equals "$COUNT_BEFORE" "$(db_query "SELECT count(*) FROM feature WHERE termination_date IS NOT NULL;")" \
  "Terminate test: all features have a termination_date"

echo ""
echo "=== Delete and Terminate Tests PASSED ==="
