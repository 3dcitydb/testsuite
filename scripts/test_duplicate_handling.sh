#!/bin/bash
set -e

source /scripts/test_helpers.sh

CONFIG_IMPORT="/config/config_citygml_import.json"
INPUT_FILE=$(resolve_citygml_input "/data/synthetic/minimal_building.gml")

echo "=== Duplicate Handling Tests ==="
echo "-------------------------------------------"

truncate_features

run_quiet citydb --config "$CONFIG_IMPORT" import citygml "$INPUT_FILE"
COUNT_FIRST=$(get_feature_count)
assert_gt 0 "$COUNT_FIRST" "Duplicate test: first import has features"

# The default import mode (import_all) imports the same features again, so
# the second import doubles the count (the other modes: IM01 in
# test_import_options.sh).
run_quiet citydb --config "$CONFIG_IMPORT" import citygml "$INPUT_FILE"
assert_equals $((2 * COUNT_FIRST)) "$(get_feature_count)" "Duplicate test: second import with the default mode inserts duplicates"

echo ""
echo "=== Duplicate Handling Tests PASSED ==="
