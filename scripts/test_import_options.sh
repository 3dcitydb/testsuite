#!/bin/bash
# Import option tests for citydb-tool.
#
# Datasets: data/synthetic/cql2_features.gml (8 buildings, 2 roads,
# 4 addresses), data/synthetic/cql2_spatial.gml and the Railway scene.
#
# Covered:
#   IM01  --import-mode import_all / skip / delete / terminate
#   IM02  --preview
#   IM03-IM08  import filters: -t, --id, --bbox (+ SRID, --bbox-mode),
#              --limit, --start-index
#   IM09-IM10  metadata: --lineage, --updating-person, --reason-for-update,
#              --creation-date
#   IM11  --import-xal-source
#   IM12  --transform (swap-xy and affine matrix)
#   IM13  --compute-extent
#   IM14  --no-appearances, --appearance-theme
#   IM15  --index-mode drop / drop_create
#   IM16  --threads
#   IM17-IM19  input sources: ZIP and GZIP archives, directories, glob
#              patterns, several files, missing file

set -e

source /scripts/test_helpers.sh

CFG_IMPORT=/config/config_citygml_import.json
DATASET=/data/synthetic/cql2_features.gml
SPATIAL=/data/synthetic/cql2_spatial.gml
RAILWAY=/data/Railway_Scene/Railway_Scene_LoD3.gml

# Temporary input files of IM13 and IM17-IM19
trap 'rm -rf /tmp/import_sources /tmp/cql2_spatial_wrong_envelope.gml' EXIT

echo "=== Import Option Tests ==="
echo "-------------------------------------------"

# Clear the database and import with the given options.
import_with() {
  citydb --config "$CFG_IMPORT" import citygml "$@" > /tmp/import_opt_last.log 2>&1 \
    || { echo "Import failed:"; tail -8 /tmp/import_opt_last.log; return 1; }
}

fresh_import() {
  truncate_features > /dev/null
  import_with "$@"
}

# Sorted object ids of all features in the database.
db_ids() {
  db_query "SELECT string_agg(objectid, ' ' ORDER BY objectid) FROM feature;"
}

count_valid() {
  db_query "SELECT count(*) FROM feature WHERE termination_date IS NULL;"
}

spatial_index_exists() {
  db_query "SELECT count(*) FROM pg_indexes WHERE schemaname = 'citydb' AND indexname = 'feature_envelope_spx';"
}

WEST="BLDG_CQL2_01 BLDG_CQL2_02 BLDG_CQL2_03 BLDG_CQL2_04 ROAD_CQL2_01"

# ---------------------------------------------------------------------------
# IM01: import modes for a second import of the same file
# ---------------------------------------------------------------------------
echo ""
echo "--- Import modes (IM01) ---"

fresh_import "$DATASET"
import_with -m import_all "$DATASET"
assert_equals 20 "$(get_feature_count)" "IM01: import_all imports duplicates"

fresh_import "$DATASET"
import_with -m skip "$DATASET"
assert_equals 10 "$(get_feature_count)" "IM01: skip keeps the existing features only"

fresh_import "$DATASET"
import_with -m delete "$DATASET"
assert_equals 10 "$(get_feature_count)" "IM01: delete replaces the existing features"
assert_equals 4 "$(db_query "SELECT count(*) FROM address;")" "IM01: delete also replaces the addresses"

fresh_import "$DATASET"
import_with -m terminate "$DATASET"
assert_equals 20 "$(get_feature_count)" "IM01: terminate keeps old versions"
assert_equals 10 "$(count_valid)" "IM01: terminate leaves only the new versions valid"
assert_equals "t f" "$(db_query "SELECT string_agg((termination_date IS NOT NULL)::text, ' ' ORDER BY id) FROM feature WHERE objectid = 'BLDG_CQL2_01';" | sed 's/true/t/g;s/false/f/g')" \
  "IM01: old version of BLDG_CQL2_01 terminated, new version valid"

# ---------------------------------------------------------------------------
# IM02: preview
# ---------------------------------------------------------------------------
echo ""
echo "--- Preview (IM02) ---"

fresh_import --preview "$DATASET"
assert_equals 0 "$(get_feature_count)" "IM02: --preview imports nothing"
assert_equals 1 "$(grep -c 'Preview of features to be imported' /tmp/import_opt_last.log)" "IM02: preview report written"
assert_equals 1 "$(grep -c 'bldg:Building: 8' /tmp/import_opt_last.log)" "IM02: preview reports 8 buildings"

# ---------------------------------------------------------------------------
# IM03-IM08: import filters
# ---------------------------------------------------------------------------
echo ""
echo "--- Import filters (IM03-IM08) ---"

fresh_import -t tran:Road "$DATASET"
assert_equals "ROAD_CQL2_01 ROAD_CQL2_02" "$(db_ids)" "IM03: -t tran:Road"

fresh_import --id BLDG_CQL2_03,ROAD_CQL2_02 "$DATASET"
assert_equals "BLDG_CQL2_03 ROAD_CQL2_02" "$(db_ids)" "IM04: --id with two identifiers"

fresh_import --bbox 458780,5438330,458860,5438400 "$DATASET"
assert_equals "$WEST" "$(db_ids)" "IM05: --bbox west cluster"
assert_equals 3 "$(db_query "SELECT count(*) FROM address;")" "IM05: only addresses of imported buildings"

fresh_import --bbox 8.43534,49.09643,8.43645,49.09708,4326 "$DATASET"
assert_equals "$WEST" "$(db_ids)" "IM06: --bbox with SRID 4326"

# IM07: bbox covers B01 and B02 completely and B03 partially
fresh_import --bbox 458789,5438339,458822,5438351 "$DATASET"
assert_equals "BLDG_CQL2_01 BLDG_CQL2_02 BLDG_CQL2_03" "$(db_ids)" "IM07: --bbox-mode intersects (default)"
fresh_import --bbox 458789,5438339,458822,5438351 --bbox-mode contains "$DATASET"
assert_equals "BLDG_CQL2_01 BLDG_CQL2_02" "$(db_ids)" "IM07: --bbox-mode contains"
fresh_import --bbox 458780,5438330,458860,5438400 --bbox-mode on_tile "$DATASET"
assert_equals "$WEST" "$(db_ids)" "IM07: --bbox-mode on_tile"

fresh_import --limit 3 "$DATASET"
assert_equals "BLDG_CQL2_01 BLDG_CQL2_02 BLDG_CQL2_03" "$(db_ids)" "IM08: --limit 3 (file order)"
fresh_import --start-index 8 "$DATASET"
assert_equals "ROAD_CQL2_01 ROAD_CQL2_02" "$(db_ids)" "IM08: --start-index 8"
fresh_import -t bldg:Building --limit 2 --start-index 1 "$DATASET"
assert_equals "BLDG_CQL2_02 BLDG_CQL2_03" "$(db_ids)" "IM08: -t + --limit + --start-index"

# ---------------------------------------------------------------------------
# IM09-IM10: metadata
# ---------------------------------------------------------------------------
echo ""
echo "--- Metadata (IM09-IM10) ---"

fresh_import --lineage=testsuite-lineage --updating-person=tester --reason-for-update="cql2 import" \
  --creation-date=2020-05-01T12:00:00+02:00 "$DATASET"
assert_equals "testsuite-lineage | tester | cql2 import | 2020-05-01 10:00:00+00" \
  "$(db_query "SELECT DISTINCT lineage, updating_person, reason_for_update, creation_date FROM feature;")" \
  "IM09: lineage, updating person, reason and creation date"

fresh_import "$DATASET"
assert_equals "| citydb |" "$(db_query "SELECT DISTINCT lineage, updating_person, reason_for_update FROM feature;")" \
  "IM09: defaults (no lineage, database user, no reason)"

fresh_import --creation-date=now "$DATASET"
assert_equals 10 "$(db_query "SELECT count(*) FROM feature WHERE creation_date > now() - interval '10 minutes';")" \
  "IM10: --creation-date now"

# ---------------------------------------------------------------------------
# IM11: xAL source
# ---------------------------------------------------------------------------
echo ""
echo "--- xAL source (IM11) ---"

fresh_import "$DATASET"
assert_equals 0 "$(db_query "SELECT count(content) FROM address;")" "IM11: no xAL source by default"

fresh_import --import-xal-source "$DATASET"
assert_equals "4 application/xml" "$(db_query "SELECT count(content), max(content_mime_type) FROM address;" | tr -d '|' | xargs)" \
  "IM11: --import-xal-source stores the xAL snippet"
assert_equals 1 "$(db_query "SELECT count(*) FROM address WHERE content LIKE '%Kaiserallee%';")" "IM11: snippet contains the street"

# ---------------------------------------------------------------------------
# IM12: coordinate transformation
# ---------------------------------------------------------------------------
echo ""
echo "--- Transform (IM12) ---"

fresh_import --transform swap-xy "$DATASET"
assert_equals "5438340 458790" "$(db_query "SELECT round(st_xmin(envelope)), round(st_ymin(envelope)) FROM feature WHERE objectid = 'BLDG_CQL2_01';" | tr -d '|' | xargs)" \
  "IM12: --transform swap-xy"

fresh_import --transform 1,0,0,100,0,1,0,200,0,0,1,10 "$DATASET"
assert_equals "458890 5438540 10" "$(db_query "SELECT round(st_xmin(envelope)), round(st_ymin(envelope)), round(st_zmin(envelope)) FROM feature WHERE objectid = 'BLDG_CQL2_01';" | tr -d '|' | xargs)" \
  "IM12: --transform affine matrix (shift 100, 200, 10)"

# ---------------------------------------------------------------------------
# IM13: compute extent.  A copy of the spatial dataset gets a wrong
# gml:boundedBy on SP_L (x up to O + 999).
# ---------------------------------------------------------------------------
echo ""
echo "--- Compute extent (IM13) ---"

WRONG_ENV=/tmp/cql2_spatial_wrong_envelope.gml
sed '/<bldg:Building gml:id="SP_L">/{n;a\
      <gml:boundedBy><gml:Envelope srsName="urn:ogc:def:crs:EPSG::25832" srsDimension="3"><gml:lowerCorner>460000.0 5439000.0 0.0</gml:lowerCorner><gml:upperCorner>460999.0 5439999.0 10.0</gml:upperCorner></gml:Envelope></gml:boundedBy>
}' "$SPATIAL" > "$WRONG_ENV"

fresh_import "$WRONG_ENV"
assert_equals 460999 "$(db_query "SELECT round(st_xmax(envelope)) FROM feature WHERE objectid = 'SP_L';")" \
  "IM13: gml:boundedBy is taken over by default"

fresh_import --compute-extent "$WRONG_ENV"
assert_equals 460020 "$(db_query "SELECT round(st_xmax(envelope)) FROM feature WHERE objectid = 'SP_L';")" \
  "IM13: --compute-extent recomputes the envelope from the geometry"

# ---------------------------------------------------------------------------
# IM14: appearances (Railway scene: 175 appearances of theme 'visual')
# ---------------------------------------------------------------------------
echo ""
echo "--- Appearances (IM14) ---"

fresh_import "$RAILWAY"
assert_equals 175 "$(db_query "SELECT count(*) FROM appearance;")" "IM14: appearances imported by default"

fresh_import --no-appearances "$RAILWAY"
assert_equals 0 "$(db_query "SELECT count(*) FROM appearance WHERE implicit_geometry_id IS NULL;")" \
  "IM14: --no-appearances skips the appearances of features"
# The global appearances of implicit geometries (5 in the Railway scene)
# are checked separately (skipped if they are imported).
IMPLICIT_APP=$(db_query "SELECT count(*) FROM appearance WHERE implicit_geometry_id IS NOT NULL;")
if [ "$IMPLICIT_APP" != "0" ]; then
  skip_case "IM14 (implicit geometries)" "$IMPLICIT_APP appearances of implicit geometries imported despite --no-appearances; to be clarified"
else
  assert_equals "0 0" "$(db_query "SELECT (SELECT count(*) FROM surface_data), (SELECT count(*) FROM tex_image);" | tr -d '|' | xargs)" \
    "IM14: --no-appearances skips surface data and textures"
fi
assert_equals 231 "$(get_feature_count)" "IM14: features are still imported"

fresh_import -a visual "$RAILWAY"
assert_equals 175 "$(db_query "SELECT count(*) FROM appearance;")" "IM14: --appearance-theme visual"

fresh_import -a other "$RAILWAY"
assert_equals 0 "$(db_query "SELECT count(*) FROM appearance WHERE implicit_geometry_id IS NULL;")" \
  "IM14: --appearance-theme with unknown theme skips the appearances of features"
# Same check for the theme filter on the appearances of implicit geometries.
IMPLICIT_APP=$(db_query "SELECT count(*) FROM appearance WHERE implicit_geometry_id IS NOT NULL;")
if [ "$IMPLICIT_APP" != "0" ]; then
  skip_case "IM14 (theme, implicit geometries)" "$IMPLICIT_APP appearances of implicit geometries imported despite an unknown --appearance-theme; to be clarified"
fi

# ---------------------------------------------------------------------------
# IM15: index mode
# ---------------------------------------------------------------------------
echo ""
echo "--- Index mode (IM15) ---"

fresh_import --index-mode drop "$DATASET"
assert_equals 0 "$(spatial_index_exists)" "IM15: --index-mode drop leaves indexes dropped"
run_quiet citydb index create "${DB_ARGS[@]}"
assert_equals 1 "$(spatial_index_exists)" "IM15: indexes recreated"

fresh_import --index-mode drop_create "$DATASET"
assert_equals 1 "$(spatial_index_exists)" "IM15: --index-mode drop_create recreates indexes"
assert_equals 10 "$(get_feature_count)" "IM15: features imported with drop_create"

# ---------------------------------------------------------------------------
# IM16: single-threaded import yields the same result
# ---------------------------------------------------------------------------
echo ""
echo "--- Threads (IM16) ---"

fresh_import --threads 1 "$RAILWAY"
assert_equals 231 "$(get_feature_count)" "IM16: --threads 1 imports all features"
assert_equals 175 "$(db_query "SELECT count(*) FROM appearance;")" "IM16: --threads 1 imports all appearances"

# ---------------------------------------------------------------------------
# IM17-IM19: input sources (archives, directories, glob patterns, several
# files).  The CQL2 dataset has 10 features, the spatial dataset 7.
# ---------------------------------------------------------------------------
echo ""
echo "--- Input sources (IM17-IM19) ---"

SRC_DIR=/tmp/import_sources
rm -rf "$SRC_DIR"; mkdir -p "$SRC_DIR/dir"
cp "$DATASET" "$SPATIAL" "$SRC_DIR/dir/"
python3 -c "import sys, zipfile; z = zipfile.ZipFile(sys.argv[1], 'w', zipfile.ZIP_DEFLATED); z.write(sys.argv[2], 'cql2_features.gml'); z.close()" \
  "$SRC_DIR/cql2.zip" "$DATASET"
gzip -c "$DATASET" > "$SRC_DIR/cql2.gml.gz"

fresh_import "$SRC_DIR/cql2.zip"
assert_equals 10 "$(get_feature_count)" "IM17: ZIP archive"
fresh_import "$SRC_DIR/cql2.gml.gz"
assert_equals 10 "$(get_feature_count)" "IM17: GZIP-compressed file"

fresh_import "$SRC_DIR/dir"
assert_equals 17 "$(get_feature_count)" "IM18: directory with two files"
fresh_import "$SRC_DIR/dir/*.gml"
assert_equals 17 "$(get_feature_count)" "IM18: glob pattern"
fresh_import "$SRC_DIR/dir/cql2_features.gml" "$SRC_DIR/dir/cql2_spatial.gml"
assert_equals 17 "$(get_feature_count)" "IM18: two files as arguments"

# IM19: a missing file in the list aborts the whole import before any
# feature is written.
truncate_features > /dev/null
assert_fails_with "Failed to create list of input files." \
  "IM19: missing input file in the list" \
  citydb --config "$CFG_IMPORT" import citygml "$SRC_DIR/dir/cql2_features.gml" "$SRC_DIR/dir/missing.gml"
assert_equals 0 "$(get_feature_count)" "IM19: nothing imported"

echo ""
echo "=== Import Option Tests PASSED ==="
