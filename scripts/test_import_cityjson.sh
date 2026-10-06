#!/bin/bash
set -e

source /scripts/test_helpers.sh

echo "=== CityJSON Import Tests ==="
echo "-------------------------------------------"

truncate_features

run_quiet citydb import cityjson "${DB_ARGS[@]}" /data/synthetic/minimal_building.city.json
echo "Import complete."

assert_equals 1 "$(get_feature_count_by_type 'Building')" "CityJSON import: building imported"

echo ""
echo "=== CityJSON Import Tests PASSED ==="
