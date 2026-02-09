#!/bin/bash
set -e

source /scripts/test_helpers.sh

CONFIG_FILE="/config/config_citygml_export.json"
OUTPUT_FILE="/output/exported_railway.gml"

echo "Running EXPORT test..."
echo "-------------------------------------------"

citydb --config $CONFIG_FILE export citygml -o $OUTPUT_FILE
echo "Export command finished."

echo "Verifying export by checking the output file..."
assert_file_exists "$OUTPUT_FILE" 3072 "CityGML export: file has meaningful content"

echo "EXPORT TEST SUCCEEDED!"
