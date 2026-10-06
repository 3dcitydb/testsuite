#!/bin/bash
set -e

source /scripts/test_helpers.sh

echo "=== Index Management Tests ==="
echo "-------------------------------------------"

# Make sure the indexes exist again for the following tests, even if a
# step fails.
trap 'citydb index create "${DB_ARGS[@]}" > /dev/null 2>&1 || true' EXIT

spatial_index_exists() {
  db_query "SELECT count(*) FROM pg_indexes WHERE schemaname = 'citydb' AND indexname = 'feature_envelope_spx';"
}

run_quiet citydb index status "${DB_ARGS[@]}"
assert_equals 1 "$(spatial_index_exists)" "Index status: spatial index exists"

run_quiet citydb index drop "${DB_ARGS[@]}"
assert_equals 0 "$(spatial_index_exists)" "Index drop: spatial index removed"
run_quiet citydb index status "${DB_ARGS[@]}"

run_quiet citydb index create "${DB_ARGS[@]}"
assert_equals 1 "$(spatial_index_exists)" "Index create: spatial index recreated"
run_quiet citydb index status "${DB_ARGS[@]}"

echo ""
echo "=== Index Management Tests PASSED ==="
