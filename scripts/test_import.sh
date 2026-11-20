#!/bin/bash
set -e

source /scripts/test_helpers.sh

CONFIG_FILE="/config/config_citygml_import.json"
INPUT_FILE=$(resolve_citygml_input "/data/Railway_Scene/Railway_Scene_LoD3.gml")

echo "Running IMPORT test..."
echo "  Input file: $INPUT_FILE"
echo "-------------------------------------------"

citydb --config $CONFIG_FILE import citygml $INPUT_FILE
echo "Import command finished."

echo "Verifying import by querying the feature table..."
COUNT=$(get_feature_count)
assert_gt 0 "$COUNT" "CityGML import: features found ($COUNT)"

echo "IMPORT TEST SUCCEEDED!"
