#!/bin/bash
set -e

source /scripts/test_helpers.sh

CONFIG_FILE="/config/config_citygml_import.json"
INPUT_FILE=$(resolve_citygml_input "/data/Railway_Scene/Railway_Scene_LoD3.gml")

echo "=== CityGML Import Tests ==="
echo "  Input file: $INPUT_FILE"
echo "-------------------------------------------"

truncate_features

run_quiet citydb --config "$CONFIG_FILE" import citygml "$INPUT_FILE"
echo "Import complete."

COUNT=$(get_feature_count)
if [ -z "${CITYGML_DATASET:-}" ]; then
  assert_equals 231 "$COUNT" "CityGML import: all features of the Railway scene imported"
else
  assert_gt 0 "$COUNT" "CityGML import: features found"
fi

echo ""
echo "=== CityGML Import Tests PASSED ==="
