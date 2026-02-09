#!/bin/bash
set -e

source /scripts/test_helpers.sh

echo "=== CityJSON Import Tests ==="
echo "-------------------------------------------"

# Clear any existing data
truncate_features

echo "Importing CityJSON file..."
citydb import cityjson \
  --db-host=db --db-name=citydb --db-username=citydb --db-password=test \
  /data/synthetic/minimal_building.city.json
echo "Import command finished."

COUNT=$(get_feature_count)
assert_gt 0 "$COUNT" "CityJSON import: features exist"

echo ""
echo "=== CityJSON Import Tests PASSED ==="
