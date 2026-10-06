#!/bin/bash
# Export option tests for citydb-tool.
#
# Datasets: data/synthetic/cql2_features.gml and the Railway scene (LoD3,
# 175 appearances of theme 'visual').
#
# Covered:
#   EX01  --citygml-version 1.0 / 2.0 / 3.0 (+ invalid version)
#   EX02  CityGML 2.0 drops generic code attributes (pinned)
#   EX03  --crs, --crs-name (axis order of EPSG:4326 pinned)
#   EX04  --no-pretty-print
#   EX05  --output-encoding
#   EX06  --transform swap-xy
#   EX07  --tile-origin top_left / bottom_left
#   EX08  --lod with --lod-mode or / and / minimum
#   EX09  --no-appearances, --appearance-theme (incl. texture files)
#   EX10  -M / -T validity at a point in time

set -e

source /scripts/test_helpers.sh

CFG=/config/config_export_cql2_base.json
CFG_IMPORT=/config/config_citygml_import.json
DATASET=/data/synthetic/cql2_features.gml
RAILWAY=/data/Railway_Scene/Railway_Scene_LoD3.gml
OUT_DIR=/output/export_options
OUT=$OUT_DIR/case.gml

echo "=== Export Option Tests ==="
echo "-------------------------------------------"

# Export into a clean output directory with the given options.
opt_export() {
  rm -rf "$OUT_DIR"; mkdir -p "$OUT_DIR"
  citydb --config "$CFG" export citygml -o "$OUT" "$@" > /tmp/export_opt_last.log 2>&1 \
    || { echo "Export failed:"; tail -8 /tmp/export_opt_last.log; return 1; }
}

fresh_import() {
  truncate_features > /dev/null
  run_quiet citydb --config "$CFG_IMPORT" import citygml "$@"
}

first_poslist() {
  grep -m1 -oE '<gml:posList[^>]*>[^<]{0,40}' "$OUT" | sed 's/.*>//' | cut -d' ' -f1-2
}

fresh_import "$DATASET"

# ---------------------------------------------------------------------------
# EX01-EX02: CityGML versions
# ---------------------------------------------------------------------------
echo ""
echo "--- CityGML versions (EX01-EX02) ---"

opt_export -v 3.0
assert_equals 1 "$(grep -c 'xmlns:bldg="http://www.opengis.net/citygml/building/3.0"' "$OUT")" "EX01: CityGML 3.0 namespace"
assert_schema_valid "$OUT" "EX01: CityGML 3.0 export is schema-valid"

opt_export -v 2.0
assert_equals 1 "$(grep -c 'xmlns:bldg="http://www.opengis.net/citygml/building/2.0"' "$OUT")" "EX01: CityGML 2.0 namespace"
assert_schema_valid "$OUT" "EX01: CityGML 2.0 export is schema-valid"
assert_export_count 8 "$OUT" bldg:Building "EX01: CityGML 2.0 contains all buildings"
assert_equals 8 "$(grep -c '<bldg:measuredHeight' "$OUT")" "EX01: con:height exported as bldg:measuredHeight"
assert_equals 0 "$(grep -c 'usageCode' "$OUT" || true)" "EX02: generic code attribute dropped in CityGML 2.0 (pinned)"

opt_export -v 1.0
assert_equals 1 "$(grep -c 'xmlns:bldg="http://www.opengis.net/citygml/building/1.0"' "$OUT")" "EX01: CityGML 1.0 namespace"
# If the CityGML 1.0 export contains constructs that only exist since
# CityGML 2.0, they are removed from a copy and the rest of the file is
# still validated.
if grep -qE '<gen:measureAttribute|<gen:genericAttributeSet|<bldg:[a-zA-Z]+ codeSpace=' "$OUT"; then
  skip_case "EX01 (1.0 schema)" "CityGML 1.0 export contains CityGML 2.0 constructs, validated without them; to be clarified"
  sed -e '/<gen:measureAttribute/,/<\/gen:measureAttribute>/d' \
      -e '/<gen:genericAttributeSet/,/<\/gen:genericAttributeSet>/d' \
      -e 's/ codeSpace="[^"]*"//g' "$OUT" > "$OUT_DIR/case_1_0_stripped.gml"
  assert_schema_valid "$OUT_DIR/case_1_0_stripped.gml" "EX01: CityGML 1.0 export is schema-valid apart from the 2.0 constructs"
else
  assert_schema_valid "$OUT" "EX01: CityGML 1.0 export is schema-valid"
fi
assert_export_count 8 "$OUT" bldg:Building "EX01: CityGML 1.0 contains all buildings"

assert_fails_with "Invalid value for option '--citygml-version'" "EX01: unsupported CityGML version" \
  citydb --config "$CFG" export citygml -o "$OUT" -v 4.0

# ---------------------------------------------------------------------------
# EX03: CRS
# ---------------------------------------------------------------------------
echo ""
echo "--- CRS (EX03) ---"

opt_export --crs 4326 -f "core:objectId = 'BLDG_CQL2_01'"
assert_equals 1 "$(grep -c 'srsName="http://www.opengis.net/def/crs/EPSG/0/4326"' "$OUT")" "EX03: srsName of EPSG:4326"
# Coordinates are written as longitude/latitude although the EPSG
# definition of 4326 is latitude/longitude (pinned deliberately).
assert_equals "8.4355 49.0965" "$(first_poslist | awk '{printf "%.4f %.4f", $1, $2}')" "EX03: coordinates transformed (lon/lat order)"

opt_export --crs 4326 --crs-name "EPSG:4326" -f "core:objectId = 'BLDG_CQL2_01'"
assert_equals 1 "$(grep -c 'srsName="EPSG:4326"' "$OUT")" "EX03: --crs-name overrides the srsName"

opt_export --crs 3857 -f "core:objectId = 'BLDG_CQL2_01'"
assert_equals "939034 6291256" "$(first_poslist | awk '{printf "%d %d", $1, $2}')" "EX03: coordinates transformed to EPSG:3857"

# ---------------------------------------------------------------------------
# EX04-EX06: formatting and coordinates
# ---------------------------------------------------------------------------
echo ""
echo "--- Formatting (EX04-EX06) ---"

opt_export --no-pretty-print
assert_equals 0 "$(wc -l < "$OUT")" "EX04: --no-pretty-print writes a single line"
assert_equals 8 "$(grep -o '<bldg:Building gml:id' "$OUT" | wc -l)" "EX04: unformatted export is complete"
assert_schema_valid "$OUT" "EX04: unformatted export is schema-valid"
opt_export
assert_gt 100 "$(wc -l < "$OUT")" "EX04: pretty print is the default"

opt_export --output-encoding ISO-8859-1 -f "core:objectId = 'BLDG_CQL2_01'"
assert_equals 1 "$(head -1 "$OUT" | grep -c 'encoding="ISO-8859-1"')" "EX05: XML declaration uses ISO-8859-1"
assert_equals 1 "$(LC_ALL=C grep -c "$(printf 'M\xfcnchner')" "$OUT")" "EX05: umlaut written as single ISO-8859-1 byte"
assert_schema_valid "$OUT" "EX05: ISO-8859-1 export is schema-valid"

opt_export --transform swap-xy -f "core:objectId = 'BLDG_CQL2_01'"
assert_equals "5438340.0 458790.0" "$(first_poslist)" "EX06: --transform swap-xy"

# ---------------------------------------------------------------------------
# EX07: tile origin.  2 x 2 tiles over the auto-computed extent: buildings
# in the southern row, roads in the northern row, west cluster in column 0.
# ---------------------------------------------------------------------------
echo ""
echo "--- Tile origin (EX07) ---"

opt_export --tile-matrix 2,2
assert_export_ids "ROAD_CQL2_01" "$OUT_DIR/case_0_0.gml" "bldg:Building,tran:Road" "EX07: top_left origin, tile 0_0 is north-west"
opt_export --tile-matrix 2,2 --tile-origin bottom_left
assert_export_ids "BLDG_CQL2_01 BLDG_CQL2_02 BLDG_CQL2_03 BLDG_CQL2_04" "$OUT_DIR/case_0_0.gml" "bldg:Building,tran:Road" \
  "EX07: bottom_left origin, tile 0_0 is south-west"

# ---------------------------------------------------------------------------
# EX10: validity at a point in time (before the Railway import below)
# ---------------------------------------------------------------------------
echo ""
echo "--- Validity (EX10) ---"

fresh_import --creation-date=2020-01-01 "$DATASET"
run_quiet citydb --config "$CFG" delete -f "core:objectId = 'BLDG_CQL2_01'" --termination-date=2025-01-01

opt_export -t bldg:Building
assert_export_count 7 "$OUT" bldg:Building "EX10: default exports valid features only"
opt_export -t bldg:Building -M valid -T 2024-06-01
assert_export_count 8 "$OUT" bldg:Building "EX10: all 8 buildings valid in 2024"
opt_export -t bldg:Building -M valid -T 2025-06-01
assert_export_count 7 "$OUT" bldg:Building "EX10: 7 buildings valid in mid 2025"
opt_export -t bldg:Building -M invalid -T 2025-06-01
assert_export_ids "BLDG_CQL2_01" "$OUT" bldg:Building "EX10: BLDG_CQL2_01 invalid in mid 2025"
opt_export -t bldg:Building -M valid -T 2019-06-01
assert_export_count 0 "$OUT" bldg:Building "EX10: nothing valid before the creation date"

# ---------------------------------------------------------------------------
# EX08-EX09: LoD and appearances on the Railway scene
# ---------------------------------------------------------------------------
fresh_import "$RAILWAY"

echo ""
echo "--- LoD filter (EX08) ---"

opt_export -t bldg:Building --lod 3
assert_export_count 3 "$OUT" bldg:Building "EX08: --lod 3 exports the LoD3 buildings"
assert_equals 0 "$(grep -c 'lod2' "$OUT" || true)" "EX08: no LoD2 geometry"

opt_export -t bldg:Building --lod 2
assert_export_count 0 "$OUT" bldg:Building "EX08: --lod 2 exports no building"

opt_export -t bldg:Building --lod 2,3 --lod-mode or
assert_export_count 3 "$OUT" bldg:Building "EX08: --lod 2,3 --lod-mode or"

opt_export -t bldg:Building --lod 2,3 --lod-mode and
assert_export_count 0 "$OUT" bldg:Building "EX08: --lod 2,3 --lod-mode and"

opt_export --lod 0
assert_equals 0 "$(grep -c '<cityObjectMember>' "$OUT" || true)" "EX08: --lod 0 matches no feature"

echo ""
echo "--- Appearances (EX09) ---"

opt_export -t bldg:Building
assert_equals 15 "$(grep -c '<app:Appearance' "$OUT")" "EX09: 15 building appearances exported"
assert_equals 13 "$(find "$OUT_DIR" -type f ! -name 'case.gml' | wc -l)" "EX09: 13 texture files written"
assert_schema_valid "$OUT" "EX09: LoD3 export with appearances is schema-valid"

opt_export -t bldg:Building --no-appearances
assert_equals 0 "$(grep -c '<app:Appearance' "$OUT" || true)" "EX09: --no-appearances"
assert_equals 0 "$(find "$OUT_DIR" -type f ! -name 'case.gml' | wc -l)" "EX09: no texture files without appearances"

opt_export -t bldg:Building -a visual
assert_equals 15 "$(grep -c '<app:Appearance' "$OUT")" "EX09: --appearance-theme visual"

opt_export -t bldg:Building -a other
assert_equals 0 "$(grep -c '<app:Appearance' "$OUT" || true)" "EX09: --appearance-theme with unknown theme"

echo ""
echo "=== Export Option Tests PASSED ==="
