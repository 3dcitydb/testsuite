#!/bin/bash
# Delete option tests for citydb-tool.
#
# Datasets: the Railway scene (buildings with boundary surfaces, openings
# and installations) and data/synthetic/cql2_features.gml.
#
# Covered:
#   DL01  --preview
#   DL02  --no-terminate-all (sub-features stay valid)
#   DL03  terminate with sub-features, --termination-date, --lineage,
#         --updating-person, --reason-for-update
#   DL04  -m delete removes sub-features, geometries and appearances
#   DL05-DL07  --limit, --start-index (the selection order is not defined,
#              so only counts are checked), --commit
#   DL08-DL09  -M invalid, -T (validity at a point in time)
#   DL10  -m delete removes the addresses of deleted buildings
#   DL11  --index-mode drop_create
#   DL12  terminating a terminated feature again changes nothing

set -e

source /scripts/test_helpers.sh

CFG=/config/config_export_cql2_base.json
CFG_IMPORT=/config/config_citygml_import.json
DATASET=/data/synthetic/cql2_features.gml
RAILWAY=/data/Railway_Scene/Railway_Scene_LoD3.gml

echo "=== Delete Option Tests ==="
echo "-------------------------------------------"

run_delete() {
  citydb --config "$CFG" delete "$@" > /tmp/delete_opt_last.log 2>&1 \
    || { echo "Delete failed:"; tail -8 /tmp/delete_opt_last.log; return 1; }
}

fresh_import() {
  truncate_features > /dev/null
  run_quiet citydb --config "$CFG_IMPORT" import citygml "$1"
}

count_valid() {
  db_query "SELECT count(*) FROM feature WHERE termination_date IS NULL;"
}

count_terminated_class() {
  db_query "SELECT count(*) FROM feature f JOIN objectclass o ON o.id = f.objectclass_id WHERE o.classname = '$1' AND f.termination_date IS NOT NULL;"
}

# ---------------------------------------------------------------------------
# DL01-DL04: Railway scene
# ---------------------------------------------------------------------------
fresh_import "$RAILWAY"
assert_equals 231 "$(get_feature_count)" "Setup: Railway scene imported"

run_delete --preview -t bldg:Building
assert_equals 231 "$(count_valid)" "DL01: --preview terminates nothing"
assert_equals 1 "$(grep -c 'bldg:Building: 3' /tmp/delete_opt_last.log)" "DL01: preview reports 3 buildings"

run_delete -t bldg:Building --no-terminate-all -f "core:name LIKE 'Station%'"
assert_equals 1 "$(count_terminated_class Building)" "DL02: station terminated"
assert_equals 0 "$(count_terminated_class WallSurface)" "DL02: --no-terminate-all keeps the wall surfaces valid"

# DL03: the chapel has 39 features in total (building, 2 installations,
# 19 boundary surfaces, 17 openings).
run_delete -t bldg:Building -f "core:name LIKE 'Chapel%'" --termination-date=2025-01-01 \
  --lineage=del-lineage --updating-person=deleter --reason-for-update=demolished
assert_equals 39 "$(db_query "SELECT count(*) FROM feature WHERE lineage = 'del-lineage';")" \
  "DL03: chapel terminated with all sub-features"
assert_equals "2025-01-01 00:00:00+00 | deleter | demolished" \
  "$(db_query "SELECT DISTINCT termination_date, updating_person, reason_for_update FROM feature WHERE lineage = 'del-lineage';")" \
  "DL03: termination date and metadata set on all terminated features"
assert_equals 11 "$(db_query "SELECT count(*) FROM feature f JOIN objectclass o ON o.id = f.objectclass_id WHERE o.classname = 'WallSurface' AND f.lineage = 'del-lineage';")" \
  "DL03: 11 wall surfaces of the chapel terminated"

# DL04: physical delete of all buildings (3 buildings + 139 sub-features)
fresh_import "$RAILWAY"
run_delete -m delete -t bldg:Building
assert_equals 89 "$(get_feature_count)" "DL04: buildings deleted with all sub-features"
assert_equals 0 "$(get_feature_count_by_type Building)" "DL04: no building left"
assert_equals 12 "$(db_query "SELECT count(*) FROM feature f JOIN objectclass o ON o.id = f.objectclass_id WHERE o.classname IN ('WallSurface', 'RoofSurface');")" \
  "DL04: only the tunnel boundary surfaces remain"
assert_equals 0 "$(db_query "SELECT count(*) FROM geometry_data WHERE feature_id IS NULL;")" "DL04: no orphaned geometries"
assert_equals 160 "$(db_query "SELECT count(*) FROM appearance;")" "DL04: appearances of the buildings removed (175 - 15)"

# ---------------------------------------------------------------------------
# DL05-DL12: CQL2 dataset
# ---------------------------------------------------------------------------
fresh_import "$DATASET"

run_delete --limit 3 -t bldg:Building
assert_equals 7 "$(count_valid)" "DL05: --limit 3 terminates 3 buildings"

run_delete --start-index 2 --limit 2 -t bldg:Building
assert_equals 5 "$(count_valid)" "DL06: --start-index 2 --limit 2 terminates 2 more buildings"

run_delete -c 1 -t tran:Road
assert_equals 0 "$(db_query "SELECT count(*) FROM feature f JOIN objectclass o ON o.id = f.objectclass_id WHERE o.classname = 'Road' AND f.termination_date IS NULL;")" \
  "DL07: --commit 1 terminates both roads"

run_delete -m delete -M invalid -T 2100-01-01
assert_equals 3 "$(get_feature_count)" "DL08: -m delete -M invalid -T removes all terminated features"
assert_equals 3 "$(count_valid)" "DL08: remaining features are valid"

fresh_import "$DATASET"
run_delete -f "core:objectId = 'BLDG_CQL2_01'"
run_delete -m delete -M invalid
assert_equals 9 "$(get_feature_count)" "DL09: -m delete -M invalid removes the terminated building only"

run_delete -m delete -t tran:Road
assert_equals 3 "$(db_query "SELECT count(*) FROM address;")" "DL10: deleting roads keeps the addresses"
run_delete -m delete -t bldg:Building -f "core:objectId = 'BLDG_CQL2_02'"
assert_equals 2 "$(db_query "SELECT count(*) FROM address;")" "DL10: deleting a building removes its address"

run_delete -m delete --index-mode drop_create -t bldg:Building -f "core:objectId = 'BLDG_CQL2_03'"
assert_equals 1 "$(db_query "SELECT count(*) FROM pg_indexes WHERE schemaname = 'citydb' AND indexname = 'feature_envelope_spx';")" \
  "DL11: indexes exist after --index-mode drop_create"
assert_equals 0 "$(db_query "SELECT count(*) FROM feature WHERE objectid = 'BLDG_CQL2_03';")" "DL11: building deleted"

run_delete -t bldg:Building -f "core:objectId = 'BLDG_CQL2_04'" --termination-date=2025-01-01
run_delete -t bldg:Building -f "core:objectId = 'BLDG_CQL2_04'" --termination-date=2025-06-01
assert_equals "2025-01-01 00:00:00+00" "$(db_query "SELECT termination_date FROM feature WHERE objectid = 'BLDG_CQL2_04';")" \
  "DL12: terminating again keeps the first termination date"

echo ""
echo "=== Delete Option Tests PASSED ==="
