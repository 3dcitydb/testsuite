#!/bin/bash
set -e

CONFIG_FILE="/config/config_citygml_export.json"
OUTPUT_FILE="/output/exported_railway.gml"

echo "🧪 Running EXPORT test..."
echo "-------------------------------------------"

citydb --config $CONFIG_FILE export citygml -o $OUTPUT_FILE
echo "✔️ Export command finished."

echo "▶️ Verifying export by checking the output file..."
if [ -s "$OUTPUT_FILE" ]; then
    echo "✔️ Verification successful: Output file created."
    echo "🎉 EXPORT TEST SUCCEEDED! 🎉"
else
    echo "❌ Verification FAILED: Output file not created or is empty."
    exit 1
fi