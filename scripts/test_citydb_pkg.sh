#!/bin/bash
# Tests for the citydb_pkg SQL function package shipped with the 3DCityDB
# schema (independent of citydb-tool).  Runs against the deterministic CQL2
# dataset; expected values derive from its known coordinates.
#
# S05 (change_schema_srid) transforms the whole schema to EPSG:4326.  The
# original SRS is restored on exit (also after a failure), clearing the
# features first, so that later tests and runs see the original schema.

set -e

source /scripts/test_helpers.sh

CFG_IMPORT=/config/config_citygml_import.json
DATASET=/data/synthetic/cql2_features.gml

echo "=== CityDB Pkg Function Tests ==="
echo "-------------------------------------------"

ORIG_SRID=$(db_query "SELECT srid FROM database_srs;")
ORIG_SRS_NAME=$(db_query "SELECT srs_name FROM database_srs;")

# Restore the original SRS if it was changed.  The features are cleared
# first, so no coordinates need to be transformed back.
restore_srid() {
  [ "$(db_query "SELECT srid FROM database_srs;")" = "$ORIG_SRID" ] && return 0
  echo "Restoring schema SRID $ORIG_SRID..."
  truncate_features > /dev/null
  db_query "SELECT citydb_pkg.change_schema_srid($ORIG_SRID, '$ORIG_SRS_NAME', 0);" > /dev/null
}
trap restore_srid EXIT

# ---------------------------------------------------------------------------
# Setup: clean import of the deterministic dataset
# ---------------------------------------------------------------------------
truncate_features

echo "Importing CQL2 test dataset..."
run_quiet citydb --config "$CFG_IMPORT" import citygml "$DATASET"
echo "Import complete."

assert_equals 10 "$(get_feature_count)" "Setup: 10 features imported"

FID_B01=$(db_query "SELECT id FROM feature WHERE objectid = 'BLDG_CQL2_01';")
FID_B02=$(db_query "SELECT id FROM feature WHERE objectid = 'BLDG_CQL2_02';")

# ---------------------------------------------------------------------------
# S01: get_feature_envelope
# ---------------------------------------------------------------------------
echo ""
echo "--- S01: get_feature_envelope ---"

# Known envelope of BLDG_CQL2_01: x 458790..458800, y 5438340..5438350, z 0..3.5
S01_COORDS=$(db_query "SELECT CASE WHEN
    abs(ST_XMin(e) - 458790)  < 0.01 AND abs(ST_XMax(e) - 458800)  < 0.01 AND
    abs(ST_YMin(e) - 5438340) < 0.01 AND abs(ST_YMax(e) - 5438350) < 0.01 AND
    abs(ST_ZMin(e) - 0)       < 0.01 AND abs(ST_ZMax(e) - 3.5)     < 0.01
  THEN 1 ELSE 0 END
  FROM (SELECT citydb_pkg.get_feature_envelope($FID_B01, 1, 0) AS e) q;")
assert_equals 1 "$S01_COORDS" "S01: computed envelope matches dataset coordinates"

S01_CONSISTENT=$(db_query "SELECT CASE WHEN
    ST_AsText(citydb_pkg.get_feature_envelope($FID_B01, 1, 0)) = ST_AsText(envelope)
  THEN 1 ELSE 0 END FROM feature WHERE id = $FID_B01;")
assert_equals 1 "$S01_CONSISTENT" "S01: consistent with feature.envelope"

# ---------------------------------------------------------------------------
# S02: CRS info functions
# ---------------------------------------------------------------------------
echo ""
echo "--- S02: CRS info functions ---"

SRS_NAME=$(db_query "SELECT coord_ref_sys_name FROM citydb_pkg.get_coord_ref_sys_info(25832);")
assert_equals "ETRS89 / UTM zone 32N" "$SRS_NAME" "S02: get_coord_ref_sys_info(25832) name"

assert_equals 0 "$(db_query 'SELECT citydb_pkg.is_db_coord_ref_sys_3d();')" \
  "S02: database CRS 25832 is not 3D"

assert_equals 1 "$(db_query 'SELECT citydb_pkg.check_srid(25832);')" \
  "S02: check_srid(25832) reports valid"

# Note: check_srid returns 0 for unknown SRIDs instead of raising an error.
assert_equals 0 "$(db_query 'SELECT citydb_pkg.check_srid(999999);')" \
  "S02: check_srid(999999) reports invalid"

# ---------------------------------------------------------------------------
# S03: transform_or_null
# ---------------------------------------------------------------------------
echo ""
echo "--- S03: transform_or_null ---"

# Reference point (458795, 5438345) in EPSG:25832 -> WGS84 (reference values
# computed with PostGIS ST_Transform)
S03_OK=$(db_query "SELECT CASE WHEN
    abs(ST_X(t) - 8.4355544) < 0.0001 AND abs(ST_Y(t) - 49.0965744) < 0.0001
  THEN 1 ELSE 0 END
  FROM (SELECT citydb_pkg.transform_or_null(
    ST_SetSRID(ST_MakePoint(458795, 5438345), 25832), 4326) AS t) q;")
assert_equals 1 "$S03_OK" "S03: reference point transforms to expected WGS84 position"

assert_equals "t" "$(db_query 'SELECT citydb_pkg.transform_or_null(NULL, 4326) IS NULL;')" \
  "S03: NULL input returns NULL"

# ---------------------------------------------------------------------------
# S04: terminate_feature / delete_feature (DB counterpart of citydb delete)
# ---------------------------------------------------------------------------
echo ""
echo "--- S04: terminate_feature / delete_feature ---"

db_query "SELECT citydb_pkg.terminate_feature($FID_B02, '{}'::jsonb, true);" > /dev/null
assert_equals "t" "$(db_query "SELECT termination_date IS NOT NULL FROM feature WHERE id = $FID_B02;")" \
  "S04: terminate_feature sets termination_date"

assert_gt 0 "$(db_query "SELECT count(*) FROM geometry_data WHERE feature_id = $FID_B01;")" \
  "S04: B01 has geometry rows before delete"

db_query "SELECT citydb_pkg.delete_feature($FID_B01);" > /dev/null
assert_equals 0 "$(db_query "SELECT count(*) FROM feature WHERE id = $FID_B01;")" \
  "S04: delete_feature removes the feature row"
assert_equals 0 "$(db_query "SELECT count(*) FROM geometry_data WHERE feature_id = $FID_B01;")" \
  "S04: dependent geometry_data rows removed"

# ---------------------------------------------------------------------------
# S05: change_schema_srid (restored afterwards)
# ---------------------------------------------------------------------------
echo ""
echo "--- S05: change_schema_srid ---"

db_query "SELECT citydb_pkg.change_schema_srid(4326, 'urn:ogc:def:crs:EPSG::4326', 1);" > /dev/null

assert_equals 4326 "$(db_query "SELECT srid FROM geometry_columns
  WHERE f_table_schema = 'citydb' AND f_table_name = 'geometry_data'
    AND f_geometry_column = 'geometry';")" \
  "S05: geometry column SRID changed to 4326"

assert_equals 4326 "$(db_query 'SELECT srid FROM database_srs;')" \
  "S05: database_srs updated to 4326"

# Transformed envelopes must now hold geographic coordinates (lon ~ 8.4).
S05_ENV=$(db_query "SELECT CASE WHEN ST_XMin(envelope) BETWEEN 8 AND 9 THEN 1 ELSE 0 END
  FROM feature WHERE objectid = 'BLDG_CQL2_03';")
assert_equals 1 "$S05_ENV" "S05: feature envelopes transformed to WGS84"

restore_srid
assert_equals "$ORIG_SRID" "$(db_query "SELECT srid FROM geometry_columns
  WHERE f_table_schema = 'citydb' AND f_table_name = 'geometry_data'
    AND f_geometry_column = 'geometry';")" \
  "S05: original schema SRID restored"

echo ""
echo "=== CityDB Pkg Function Tests PASSED ==="
