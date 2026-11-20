#!/bin/bash
set -e

source /scripts/test_helpers.sh

CONFIG_FILE="/config/config_citygml_export.json"
OUTPUT_FILE="/output/exported_railway.gml"

echo "=== CityGML Export Tests ==="
echo "-------------------------------------------"

# The export reads the data imported by test_import.sh.
TOP_LEVEL=$(db_query "SELECT count(*) FROM feature f JOIN objectclass o ON o.id = f.objectclass_id WHERE o.is_toplevel = 1 AND f.termination_date IS NULL;")
assert_gt 0 "$TOP_LEVEL" "Pre-export: database contains top-level features (run the import test first)"

rm -f "$OUTPUT_FILE"
run_quiet citydb --config "$CONFIG_FILE" export citygml -o "$OUTPUT_FILE"
echo "Export complete."

assert_file_exists "$OUTPUT_FILE" 3072 "CityGML export: file has meaningful content"
assert_equals "$TOP_LEVEL" "$(grep -c '<cityObjectMember>' "$OUTPUT_FILE" || true)" \
  "CityGML export: all top-level features exported"

# A custom dataset that is not schema-valid itself cannot be expected to
# yield a valid export.
if [ -n "${CITYGML_DATASET:-}" ] && ! validate_citygml "$CITYGML_DATASET" > /dev/null; then
  skip_case "Schema validation" "custom dataset $CITYGML_DATASET is not schema-valid itself"
else
  assert_schema_valid "$OUTPUT_FILE" "CityGML export: schema-valid"
fi

echo ""
echo "=== CityGML Export Tests PASSED ==="
