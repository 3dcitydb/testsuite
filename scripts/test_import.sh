#!/bin/bash
set -e

CONFIG_FILE="/config/config_citygml_import.json"
INPUT_FILE="/data/Railway_Scene/Railway_Scene_LoD3.gml"

echo "🧪 Running IMPORT test..."
echo "-------------------------------------------"

citydb --config $CONFIG_FILE import citygml $INPUT_FILE
echo "✔️ Import command finished."

echo "▶️ Verifying import by querying the feature table..."
export PGPASSWORD=test
COUNT=$(psql -h db -U citydb -d citydb -t -c "SELECT count(*) FROM feature;")
COUNT=$(echo $COUNT | xargs)

if [ "$COUNT" -gt 0 ]; then
    echo "✔️ Verification successful: Found $COUNT features."
    echo "🎉 IMPORT TEST SUCCEEDED! 🎉"
else
    echo "❌ Verification FAILED: No features found."
    exit 1
fi