#!/bin/bash
set -e

source /scripts/test_helpers.sh

CONFIG_IMPORT="/config/config_citygml_import.json"
INPUT_FILE="/data/synthetic/minimal_building.gml"

echo "=== Duplicate Handling Tests ==="
echo "-------------------------------------------"

# Clear database
truncate_features

# First import
echo "First import..."
citydb --config $CONFIG_IMPORT import citygml $INPUT_FILE
echo "First import complete."

COUNT_FIRST=$(get_feature_count)
assert_gt 0 "$COUNT_FIRST" "Duplicate test: first import has features"
echo "Feature count after first import: $COUNT_FIRST"

# Second import of same data
echo ""
echo "Second import of same data..."
citydb --config $CONFIG_IMPORT import citygml $INPUT_FILE
echo "Second import complete."

COUNT_SECOND=$(get_feature_count)
assert_gt 0 "$COUNT_SECOND" "Duplicate test: features still exist after second import"
echo "Feature count after second import: $COUNT_SECOND"

# Document behavior: the count may stay the same (upsert/skip) or double (insert)
echo ""
echo "First import count:  $COUNT_FIRST"
echo "Second import count: $COUNT_SECOND"

if [ "$COUNT_SECOND" -eq "$COUNT_FIRST" ]; then
  echo "PASS: Duplicate handling - tool performed upsert/skip (count unchanged)"
  report_line "- PASS: Duplicate handling — upsert/skip (count unchanged at $COUNT_FIRST)"
elif [ "$COUNT_SECOND" -gt "$COUNT_FIRST" ]; then
  echo "PASS: Duplicate handling - tool inserted duplicates (count increased from $COUNT_FIRST to $COUNT_SECOND)"
  report_line "- PASS: Duplicate handling — duplicates inserted ($COUNT_FIRST -> $COUNT_SECOND)"
else
  echo "FAIL: Duplicate handling - unexpected behavior (count decreased)"
  report_line "- **FAIL:** Duplicate handling — unexpected count decrease ($COUNT_FIRST -> $COUNT_SECOND)"
  exit 1
fi

echo ""
echo "=== Duplicate Handling Tests PASSED ==="
