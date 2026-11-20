#!/bin/bash
set -e

source /scripts/test_helpers.sh

CONFIG_IMPORT="/config/config_citygml_import.json"
CONFIG_DB="/config/config_export_cql2_base.json"
INPUT_FILE=$(resolve_citygml_input "/data/synthetic/minimal_building.gml")
CQL2_DATASET="/data/synthetic/cql2_features.gml"
INFO_JSON="/output/info_report.json"

# The info JSON is pretty-printed with one '"key":value' pair per line, so a
# key can be looked up with grep (the container has no jq).  An optional
# section key restricts the lookup to the lines after that key.
# Usage: json_value <file> <key> [<section key>]
json_value() {
  local file="$1"
  local key="$2"
  local section="${3:-}"
  if [ -n "$section" ]; then
    sed -n "/\"$section\":{/,\$p" "$file"
  else
    cat "$file"
  fi | grep -m1 -oE "\"$key\":[^,{]+" | cut -d: -f2- | tr -d '"'
}

# Run 'citydb info' with JSON output and fail with the log on errors.
info_json() {
  rm -f "$INFO_JSON"
  citydb --config "$CONFIG_DB" info -o "$INFO_JSON" "$@" > /tmp/info_last.log 2>&1 \
    || { echo "Info failed:"; tail -8 /tmp/info_last.log; return 1; }
}

echo "=== Info Command Tests ==="
echo "-------------------------------------------"

# Ensure there is data in the database
truncate_features
run_quiet citydb --config "$CONFIG_IMPORT" import citygml "$INPUT_FILE"
assert_gt 0 "$(get_feature_count)" "Info test: features exist for info query"

# Plain-text report with the connection given as command-line options
echo ""
echo "--- Test: Database info ---"
run_quiet citydb info "${DB_ARGS[@]}"
assert_gt 0 "$(grep -c 'citydb@db:5432/citydb' /tmp/run_quiet_last.log || true)" \
  "Info: plain-text report via command-line connection options"

# JSON report for the imported data (works for custom datasets as well)
echo ""
echo "--- Test: JSON report ---"
info_json
assert_file_exists "$INFO_JSON" 100 "I01: JSON report written"
assert_equals "$(db_query "SELECT count(*) FROM feature WHERE termination_date IS NULL;")" \
  "$(json_value "$INFO_JSON" active featureCount)" "I01: active feature count matches DB"
assert_equals 25832 "$(json_value "$INFO_JSON" srid)" "I01: SRID reported"

rm -f "$INFO_JSON"
citydb --config "$CONFIG_DB" info -o - > "$INFO_JSON" 2> /tmp/info_last.log \
  || { echo "Info failed:"; tail -8 /tmp/info_last.log; exit 1; }
assert_equals "{" "$(head -c 1 "$INFO_JSON")" "I02: '-o -' writes JSON to stdout"

info_json -c
assert_equals 0 "$(grep -c '"featureCount"' "$INFO_JSON" || true)" "I03: compact report has no feature statistics"

# ---------------------------------------------------------------------------
# Deterministic checks on the CQL2 dataset (8 buildings, 2 roads,
# 4 addresses; the generic attribute 'street' exists on BLDG_CQL2_01 only)
# ---------------------------------------------------------------------------
echo ""
echo "--- Test: Report contents (CQL2 dataset) ---"
truncate_features
run_quiet citydb --config "$CONFIG_IMPORT" import citygml "$CQL2_DATASET"

info_json --include-generic-attributes
assert_equals 10 "$(json_value "$INFO_JSON" active featureCount)" "I04: 10 active features"
assert_equals 8 "$(json_value "$INFO_JSON" active 'bldg:Building')" "I04: 8 active buildings by type"
assert_equals 2 "$(json_value "$INFO_JSON" active 'tran:Road')" "I04: 2 active roads by type"
assert_equals 4 "$(json_value "$INFO_JSON" addressCount)" "I04: 4 addresses"
assert_equals true "$(json_value "$INFO_JSON" genericAttributesProcessed)" "I05: generic attributes processed"
assert_equals 1 "$(sed -n '/"genericAttributes"/,$p' "$INFO_JSON" | grep -A1 '"storeys"' | grep -c 'core:Integer')" \
  "I05: generic attribute 'storeys' reported as core:Integer"

# Terminate BLDG_CQL2_01: counts show it as terminated in both scopes, but
# only scope 'all' still considers its address and generic attributes.
run_quiet citydb --config "$CONFIG_DB" delete -f "core:objectId = 'BLDG_CQL2_01'"

info_json --feature-scope=all --include-generic-attributes
assert_equals 1 "$(json_value "$INFO_JSON" terminated featureCount)" "I06: 1 terminated feature"
assert_equals 4 "$(json_value "$INFO_JSON" addressCount)" "I06: scope all counts 4 addresses"
assert_equals 1 "$(grep -c '"street"' "$INFO_JSON" || true)" "I06: scope all lists generic attribute 'street'"

info_json --feature-scope=active --include-generic-attributes
assert_equals active "$(json_value "$INFO_JSON" featureScope)" "I07: feature scope active in metadata"
assert_equals 9 "$(json_value "$INFO_JSON" active featureCount)" "I07: 9 active features"
assert_equals 3 "$(json_value "$INFO_JSON" addressCount)" "I07: scope active counts 3 addresses"
assert_equals 0 "$(grep -c '"street"' "$INFO_JSON" || true)" "I07: scope active omits generic attribute 'street'"

echo ""
echo "=== Info Command Tests PASSED ==="
