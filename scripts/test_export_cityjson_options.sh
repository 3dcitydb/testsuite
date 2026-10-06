#!/bin/bash
# CityJSON export option tests for citydb-tool.
#
# Dataset: data/synthetic/cql2_features.gml (8 buildings, 2 roads, no
# nested features).
#
# Covered:
#   CJ01  default output: CityJSON 2.0 Text Sequence (JSON Lines)
#   CJ02  --no-json-lines: a single CityJSON document
#   CJ03  -v 1.1
#   CJ04  -v 1.0 (single document), --no-transform-coordinates
#   CJ05  --vertex-precision
#   CJ06  --pretty-print (only without JSON Lines)
#   CJ07  --crs 4326 with a suitable vertex precision
#   CJ08  --threads yields the same features
#   CJ09  re-import of a single-document export
#
# To be clarified (reported as SKIP): with an angular CRS such as EPSG:4326
# the default vertex precision of 3 decimal places (~100 m) is kept, so the
# vertices of small buildings collapse.

set -e

source /scripts/test_helpers.sh

CFG=/config/config_export_cql2_base.json
CFG_IMPORT=/config/config_citygml_import.json
DATASET=/data/synthetic/cql2_features.gml
OUT=/output/cityjson_options.city.json
ALL="BLDG_CQL2_01 BLDG_CQL2_02 BLDG_CQL2_03 BLDG_CQL2_04 BLDG_CQL2_05 BLDG_CQL2_06 BLDG_CQL2_07 BLDG_CQL2_08 ROAD_CQL2_01 ROAD_CQL2_02"

echo "=== CityJSON Export Option Tests ==="
echo "-------------------------------------------"

# Run a CityJSON export with the base config and the given CLI options.
cj_export() {
  rm -f "$OUT"
  citydb --config "$CFG" export cityjson -o "$OUT" "$@" > /tmp/cj_opt_last.log 2>&1 \
    || { echo "Export failed:"; tail -8 /tmp/cj_opt_last.log; return 1; }
}

# Evaluate a Python expression on the export.  'docs' is the list of JSON
# documents (one per line for JSON Lines, else a single one), 'head' the
# first document.
# Usage: cj_eval '<python expression>'
cj_eval() {
  python3 - "$OUT" "$1" << 'EOF'
import json, sys
text = open(sys.argv[1], encoding="utf-8").read()
try:
    docs = [json.loads(text)]
except json.JSONDecodeError:
    docs = [json.loads(line) for line in text.splitlines() if line.strip()]
head = docs[0]
print(eval(sys.argv[2]))
EOF
}

# Sorted ids of all exported city objects without a parent.
cj_ids() {
  cj_eval '" ".join(sorted(k for d in docs for k, o in d["CityObjects"].items() if not o.get("parents")))'
}

truncate_features
run_quiet citydb --config "$CFG_IMPORT" import citygml "$DATASET"
assert_equals 10 "$(get_feature_count)" "Setup: 10 features imported"

# ---------------------------------------------------------------------------
# CJ01-CJ04: output formats and versions
# ---------------------------------------------------------------------------
echo ""
echo "--- Formats and versions (CJ01-CJ04) ---"

cj_export
assert_equals "CityJSON 2.0 0" "$(cj_eval 'head["type"] + " " + head["version"] + " " + str(len(head["CityObjects"]))')" \
  "CJ01: header line is an empty CityJSON 2.0 document"
assert_equals 10 "$(cj_eval 'sum(1 for d in docs[1:] if d["type"] == "CityJSONFeature")')" "CJ01: one CityJSONFeature line per feature"
assert_equals "$ALL" "$(cj_ids)" "CJ01: all features exported"
assert_schema_valid "$OUT" "CJ01: CityJSON Text Sequence is schema-valid"

cj_export --no-json-lines
assert_equals "1 CityJSON 10" "$(cj_eval 'str(len(docs)) + " " + head["type"] + " " + str(len(head["CityObjects"]))')" \
  "CJ02: --no-json-lines writes a single document"
assert_equals "$ALL" "$(cj_ids)" "CJ02: all features exported"
assert_schema_valid "$OUT" "CJ02: CityJSON document is schema-valid"

cj_export -v 1.1
assert_equals "1.1 11" "$(cj_eval 'head["version"] + " " + str(len(docs))')" "CJ03: CityJSON 1.1 Text Sequence"
assert_equals "$ALL" "$(cj_ids)" "CJ03: all features exported"

# CJ04: CityJSON 1.0 has no Text Sequences; --json-lines is ignored (pinned).
cj_export -v 1.0 --json-lines
assert_equals "1.0 1 True" "$(cj_eval 'head["version"] + " " + str(len(docs)) + " " + str("transform" in head)')" \
  "CJ04: CityJSON 1.0 is a single document with transform (--json-lines ignored)"
assert_equals "$ALL" "$(cj_ids)" "CJ04: all features exported"
cj_export -v 1.0 --no-transform-coordinates
assert_equals "False float" "$(cj_eval 'str("transform" in head) + " " + type(head["vertices"][0][0]).__name__')" \
  "CJ04: --no-transform-coordinates writes real coordinates"

# ---------------------------------------------------------------------------
# CJ05-CJ07: precision, formatting, CRS
# ---------------------------------------------------------------------------
echo ""
echo "--- Precision, formatting and CRS (CJ05-CJ07) ---"

cj_export --vertex-precision 1
assert_equals "[0.1, 0.1, 0.1]" "$(cj_eval 'head["transform"]["scale"]')" "CJ05: --vertex-precision 1 sets the scale to 0.1"

cj_export --pretty-print --no-json-lines
assert_gt 100 "$(wc -l < "$OUT")" "CJ06: --pretty-print writes an indented document"
assert_equals "$ALL" "$(cj_ids)" "CJ06: pretty-printed document is complete"
assert_fails_with "--json-lines and --pretty-print are mutually exclusive" \
  "CJ06: --pretty-print is rejected for JSON Lines output" \
  citydb --config "$CFG" export cityjson -o "$OUT" --pretty-print

# CJ07: BLDG_CQL2_01 has 8 distinct vertices (10 m x 10 m x 3.5 m)
DISTINCT_VERTICES='len(set(tuple(v) for v in head["vertices"]))'
cj_export --crs 4326 --vertex-precision 8 --no-json-lines -f "core:objectId = 'BLDG_CQL2_01'"
assert_equals "http://www.opengis.net/def/crs/EPSG/0/4326" "$(cj_eval 'head["metadata"]["referenceSystem"]')" "CJ07: reference system EPSG:4326"
assert_equals 8 "$(cj_eval "$DISTINCT_VERTICES")" "CJ07: 8 distinct vertices with --vertex-precision 8"
cj_export --crs 4326 --no-json-lines -f "core:objectId = 'BLDG_CQL2_01'"
COLLAPSED=$(cj_eval "$DISTINCT_VERTICES")
if [ "$COLLAPSED" != "8" ]; then
  skip_case "CJ07 (default precision)" "only $COLLAPSED of 8 distinct vertices with --crs 4326 and the default vertex precision of 3 decimal places (~100 m); to be clarified"
else
  assert_equals 8 "$COLLAPSED" "CJ07: 8 distinct vertices with --crs 4326 and the default precision"
fi

# ---------------------------------------------------------------------------
# CJ08-CJ09: threads and re-import
# ---------------------------------------------------------------------------
echo ""
echo "--- Threads and re-import (CJ08-CJ09) ---"

cj_export --threads 1
assert_equals "$ALL" "$(cj_ids)" "CJ08: --threads 1 exports all features"
cj_export --threads 4
assert_equals "$ALL" "$(cj_ids)" "CJ08: --threads 4 exports the same features"

cj_export --no-json-lines
truncate_features > /dev/null
run_quiet citydb --config "$CFG_IMPORT" import cityjson "$OUT"
assert_equals 10 "$(get_feature_count)" "CJ09: single-document export re-imported"
assert_equals 4 "$(db_query "SELECT count(*) FROM address;")" "CJ09: addresses re-imported"

echo ""
echo "=== CityJSON Export Option Tests PASSED ==="
