#!/bin/bash
set -e

CONFIG_FILE="/config/config_citygml_export.json"
OUTPUT_FILE="/output/exported_railway.gml"

echo "🧪 Running EXPORT test..."
echo "-------------------------------------------"

citydb --config $CONFIG_FILE export citygml -o $OUTPUT_FILE
echo "✔️ Export command finished."

echo "▶️ Verifying export by checking the output file size..."

# Define a minimum file size threshold in bytes (e.g., 3 KB -> if 0 Features are exported)
THRESHOLD=3072

if [ -f "$OUTPUT_FILE" ]; then
    # Get the actual file size in bytes
    FILESIZE=$(stat -c %s "$OUTPUT_FILE")

    if [ $FILESIZE -gt $THRESHOLD ]; then
        echo "✔️ Verification successful: Output file created with size ${FILESIZE} bytes (greater than ${THRESHOLD} bytes)."
        echo "🎉 EXPORT TEST SUCCEEDED! 🎉"
    else
        echo "❌ Verification FAILED: Output file size is ${FILESIZE} bytes, which is not greater than the threshold of ${THRESHOLD} bytes."
        exit 1
    fi
else
    echo "❌ Verification FAILED: Output file not found."
    exit 1
fi