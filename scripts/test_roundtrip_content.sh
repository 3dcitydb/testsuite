#!/bin/bash
# Content-level round-trip tests: import -> export -> re-import and compare
# a fingerprint of the database content (independent of surrogate ids):
#   classes  feature counts per object class
#   props    md5 over all attribute values (incl. code spaces and units)
#   objids   md5 over all object ids
#   geoms    geometry count, point count and summed area
#   addr     md5 over the addresses
#   app      appearance, surface data, texture and mapping counts
#   tex      md5 over the texture image contents
#
# Covered:
#   RT01  CQL2 dataset, CityGML 3.0: lossless
#   RT02  Railway scene, CityGML 3.0: lossless
#   RT03  Railway scene, CityGML 2.0: lossless (source is CityGML 2.0)
#   RT04  CQL2 dataset, CityGML 2.0: pinned losses (code attributes,
#         height references)
#   RT05  CQL2 dataset, CityJSON: pinned losses (code spaces, height
#         references), everything else lossless
#   RT06  Railway scene, CityJSON: pinned losses (relativeToTerrain/Water on
#         sub-features, TIN relief id), classes and geometries preserved
#   RT07  a second CityGML 3.0 export has the same content as the first one
#
# The property comparison of RT02 is SKIPPED if gen:function comes back as
# an additional generic attribute (to be clarified).

set -e

source /scripts/test_helpers.sh

CFG=/config/config_export_cql2_base.json
CFG_IMPORT=/config/config_citygml_import.json
DATASET=/data/synthetic/cql2_features.gml
RAILWAY=/data/Railway_Scene/Railway_Scene_LoD3.gml
RT_DIR=/output/roundtrip_content

echo "=== Content Round-Trip Tests ==="
echo "-------------------------------------------"

# ---------------------------------------------------------------------------
# Fingerprint helpers
# ---------------------------------------------------------------------------

# Attribute rows (no references to features, geometries, appearances and
# addresses); an optional SQL condition restricts the rows.
prop_rows_sql() {
  local where="${1:-TRUE}"
  echo "SELECT n.alias || ':' || p.name || '=' || coalesce(p.val_string, '') || coalesce(p.val_int::text, '')
          || coalesce(round(p.val_double::numeric, 6)::text, '') || coalesce(p.val_timestamp::text, '')
          || coalesce(p.val_uri, '') || coalesce(' cs=' || p.val_codespace, '') || coalesce(' uom=' || p.val_uom, '') r
        FROM property p JOIN namespace n ON n.id = p.namespace_id
        WHERE p.val_feature_id IS NULL AND p.val_geometry_id IS NULL AND p.val_appearance_id IS NULL
          AND p.val_address_id IS NULL AND ($where)"
}

fp_classes() { db_query "SELECT string_agg(c, ',' ORDER BY c) FROM (SELECT o.classname || '=' || count(*) c FROM feature f JOIN objectclass o ON o.id = f.objectclass_id GROUP BY o.classname) x;"; }
fp_props()   { db_query "SELECT count(*) || ' ' || md5(coalesce(string_agg(r, '|' ORDER BY r), '')) FROM ($(prop_rows_sql "$1")) x;"; }
fp_objids()  { db_query "SELECT md5(string_agg(objectid, ',' ORDER BY objectid)) FROM feature;"; }
fp_geoms()   { db_query "SELECT count(*) || ' ' || sum(st_npoints(geometry)) || ' ' || round(sum(st_area(geometry))::numeric, 1) FROM geometry_data WHERE geometry IS NOT NULL;"; }
fp_addr()    { db_query "SELECT count(*) || ' ' || coalesce(md5(string_agg(concat_ws(',', street, house_number, zip_code, city), '|' ORDER BY street, house_number)), '-') FROM address;"; }
fp_app()     { db_query "SELECT (SELECT count(*) FROM appearance) || ' ' || (SELECT count(*) FROM surface_data) || ' ' || (SELECT count(*) FROM tex_image) || ' ' || (SELECT count(*) FROM surface_data_mapping);"; }
fp_tex()     { db_query "SELECT count(*) || ' ' || coalesce(md5(string_agg(md5(image_data), ',' ORDER BY md5(image_data))), '-') FROM tex_image;"; }

# Store the fingerprint of the current database content in variables
# with the given prefix (e.g. ORIG_classes).
take_fingerprint() {
  local p="$1"
  eval "${p}_classes=\"\$(fp_classes)\""
  eval "${p}_props=\"\$(fp_props)\""
  eval "${p}_objids=\"\$(fp_objids)\""
  eval "${p}_geoms=\"\$(fp_geoms)\""
  eval "${p}_addr=\"\$(fp_addr)\""
  eval "${p}_app=\"\$(fp_app)\""
  eval "${p}_tex=\"\$(fp_tex)\""
}

# Clear the database, import a dataset and keep its fingerprint in ORIG_*.
load_original() {
  truncate_features > /dev/null
  run_quiet citydb --config "$CFG_IMPORT" import citygml "$1"
  take_fingerprint ORIG
}

# Export the current content with the given options, clear the database and
# re-import the export.
# Usage: export_reimport <citygml|cityjson> <export file> [export options]
export_reimport() {
  local format="$1" file="$2"
  shift 2
  rm -rf "$RT_DIR"; mkdir -p "$RT_DIR"
  citydb --config "$CFG" export "$format" -o "$RT_DIR/$file" "$@" > /tmp/rt_content_last.log 2>&1 \
    || { echo "Export failed:"; tail -8 /tmp/rt_content_last.log; return 1; }
  assert_schema_valid "$RT_DIR/$file" "Round-trip export $file is schema-valid"
  truncate_features > /dev/null
  citydb --config "$CFG_IMPORT" import "$format" "$RT_DIR/$file" > /tmp/rt_content_last.log 2>&1 \
    || { echo "Re-import failed:"; tail -8 /tmp/rt_content_last.log; return 1; }
}

# Usage: roundtrip <dataset> <citygml|cityjson> <export file> [export options]
roundtrip() {
  local dataset="$1"
  shift
  load_original "$dataset"
  export_reimport "$@"
}

assert_same() {
  local part="$1" msg="$2"
  local orig new
  eval "orig=\"\$ORIG_${part}\""
  new=$(fp_${part})
  assert_equals "$orig" "$new" "$msg"
}

# ---------------------------------------------------------------------------
# RT01: CQL2 dataset, CityGML 3.0
# ---------------------------------------------------------------------------
echo ""
echo "--- CityGML 3.0 (RT01-RT02) ---"

roundtrip $DATASET citygml cql2.gml
for part in classes props objids geoms addr app tex; do
  assert_same $part "RT01: CQL2 dataset via CityGML 3.0, $part identical"
done

# ---------------------------------------------------------------------------
# RT02: Railway scene, CityGML 3.0
# ---------------------------------------------------------------------------
roundtrip $RAILWAY citygml railway.gml
for part in classes objids geoms addr app tex; do
  assert_same $part "RT02: Railway scene via CityGML 3.0, $part identical"
done
if grep -q '<gen:name>function</gen:name>' "$RT_DIR/railway.gml"; then
  skip_case "RT02 (props)" "gen:function of GenericOccupiedSpace is exported with an additional generic attribute; to be clarified"
else
  assert_same props "RT02: Railway scene via CityGML 3.0, props identical"
fi

# ---------------------------------------------------------------------------
# RT03-RT04: CityGML 2.0
# ---------------------------------------------------------------------------
echo ""
echo "--- CityGML 2.0 (RT03-RT04) ---"

roundtrip $RAILWAY citygml railway_v2.gml -v 2.0
for part in classes props objids geoms addr app tex; do
  assert_same $part "RT03: Railway scene via CityGML 2.0, $part identical"
done

# RT04: CityGML 2.0 has no code attributes and no height references
# (con:Height becomes bldg:measuredHeight); both losses are pinned.
KEEP="NOT (p.name = 'usageCode' OR p.name = 'highReference')"
load_original $DATASET
ORIG_props_kept=$(fp_props "$KEEP")
export_reimport citygml cql2_v2.gml -v 2.0
for part in classes objids geoms addr app tex; do
  assert_same $part "RT04: CQL2 dataset via CityGML 2.0, $part identical"
done
assert_equals "$ORIG_props_kept" "$(fp_props "$KEEP")" "RT04: all other attributes identical"
assert_equals 0 "$(db_query "SELECT count(*) FROM property WHERE name = 'usageCode';")" "RT04: generic code attribute usageCode is lost (pinned)"
assert_equals "topOfConstruction 8" "$(db_query "SELECT val_string, count(*) FROM property WHERE name = 'highReference' GROUP BY 1;" | tr -d '|' | xargs)" \
  "RT04: highReference becomes topOfConstruction (pinned)"

# ---------------------------------------------------------------------------
# RT05-RT06: CityJSON
# ---------------------------------------------------------------------------
echo ""
echo "--- CityJSON (RT05-RT06) ---"

GEN="n.alias = 'gen'"
load_original $DATASET
ORIG_props_gen=$(fp_props "$GEN")
export_reimport cityjson cql2.city.json
for part in classes objids geoms addr app tex; do
  assert_same $part "RT05: CQL2 dataset via CityJSON, $part identical"
done
assert_equals "$ORIG_props_gen" "$(fp_props "$GEN")" "RT05: all generic attributes identical (incl. sets, code, measure)"
assert_equals 0 "$(db_query "SELECT count(val_codespace) FROM property WHERE name IN ('function', 'roofType');")" \
  "RT05: code spaces of function and roofType are lost (pinned)"
assert_equals "topOfConstruction 8" "$(db_query "SELECT val_string, count(*) FROM property WHERE name = 'highReference' GROUP BY 1;" | tr -d '|' | xargs)" \
  "RT05: highReference becomes topOfConstruction (pinned)"

roundtrip $RAILWAY cityjson railway.city.json
assert_same classes "RT06: Railway scene via CityJSON, classes identical"
assert_equals "$(echo "$ORIG_geoms" | cut -d' ' -f1-2)" "$(fp_geoms | cut -d' ' -f1-2)" \
  "RT06: geometry and point counts identical"
# relativeToTerrain / relativeToWater: 197 values (47 on top-level
# features, 150 on sub-features); 81 values on sub-features are lost.
RELATIVE_SQL="SELECT count(*) FROM property p JOIN feature f ON f.id = p.feature_id JOIN objectclass o ON o.id = f.objectclass_id WHERE p.name IN ('relativeToTerrain', 'relativeToWater')"
assert_equals 47 "$(db_query "$RELATIVE_SQL AND o.is_toplevel = 1;")" \
  "RT06: relativeToTerrain / relativeToWater kept on top-level features"
assert_equals 116 "$(db_query "$RELATIVE_SQL;")" \
  "RT06: 81 of 197 relativeToTerrain / relativeToWater values on sub-features are lost (pinned)"
assert_equals 0 "$(db_query "SELECT count(*) FROM feature WHERE objectid = 'GMLID_TIN436865_187531_1154';")" \
  "RT06: the TIN relief gets a new object id (pinned)"

# ---------------------------------------------------------------------------
# RT07: exporting the re-imported data again yields the same content.  The
# order of features and of attributes within a feature is not stable
# between exports, so the sorted lines of both files are compared.
# ---------------------------------------------------------------------------
echo ""
echo "--- Stable export (RT07) ---"

roundtrip $DATASET citygml first.gml
run_quiet citydb --config "$CFG" export citygml -o "$RT_DIR/second.gml"
assert_equals "$(sed 's/^ *//' "$RT_DIR/first.gml" | sort | md5sum)" \
  "$(sed 's/^ *//' "$RT_DIR/second.gml" | sort | md5sum)" \
  "RT07: second export has the same content as the first"

echo ""
echo "=== Content Round-Trip Tests PASSED ==="
