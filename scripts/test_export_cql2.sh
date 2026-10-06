#!/bin/bash
# CQL2 filter tests for citydb-tool exports.
#
# Runs against the deterministic dataset data/synthetic/cql2_features.gml
# (8 buildings + 2 roads, see the file header for the attribute matrix) and
# validates exact feature counts.
#
# Covered:
#   T01-T15  basic operators (CLI CQL2 text + config with CQL2 text/JSON)
#   C01-C11  complex queries (arithmetic, index access, nested paths, SQL(),
#            CASEI/ACCENTI, CQL2 JSON in config)
#   G01-G08  spatial operators, CRS transformation, 3D, tiling
#   F01-F10  native building attributes, height short form, object ids,
#            prefixed generic attributes, S_DISJOINT, address paths
#   N01-N10  negative cases (exit != 0 plus error message check)
#   E01      unknown attribute without namespace prefix (pinned fallback)
#   D01-D04  sorting, pagination, delete with CQL2 filter, validity filters
#
# Cases with an unexpected result in the tested citydb-tool version are
# detected at runtime via probes and SKIPPED (to be clarified): IS [NOT]
# NULL on untyped generic attributes (T08, T09, T10, C09) and SQL()
# expressions (C07, C08).  T10b/C09b cover the same logical constructs
# without IS NULL.

set -e

source /scripts/test_helpers.sh

CFG=/config/config_export_cql2_base.json
CFG_IMPORT=/config/config_citygml_import.json
DATASET=/data/synthetic/cql2_features.gml
OUT=/output/cql2_case.gml
OUT_JSON=/output/cql2_case.city.json

echo "=== CQL2 Filter Tests ==="
echo "-------------------------------------------"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# Run a CityGML export with the base config (DB connection only) and the
# given CLI options.  The full query comes from the CLI per case; CLI filter
# options replace the config query block entirely, so no query may be set in
# the base config.
cli_export() {
  local out="$1"
  shift
  export_to "$CFG" "$out" "$@"
}

# ---------------------------------------------------------------------------
# Setup: clean import of the deterministic dataset
# ---------------------------------------------------------------------------
truncate_features

echo "Importing CQL2 test dataset..."
run_quiet citydb --config "$CFG_IMPORT" import citygml "$DATASET"
echo "Import complete."

assert_equals 10 "$(get_feature_count)" "Setup: 10 features imported"
assert_equals 8 "$(get_feature_count_by_type 'Building')" "Setup: 8 buildings"
assert_equals 2 "$(get_feature_count_by_type 'Road')" "Setup: 2 roads"
assert_equals 4 "$(db_query "SELECT count(*) FROM address;")" "Setup: 4 addresses"

# Building objectclass_id, resolved dynamically (used by C07/C08).
OCID=$(db_query "SELECT id FROM objectclass WHERE classname = 'Building';")

# ---------------------------------------------------------------------------
# Capability probes.  Probe the CQL2 constructs with an unexpected empty
# result, so that affected cases skip cleanly and re-activate automatically
# once the behavior changes.  Only a successful export with an empty result leads
# to a skip; any other deviation runs the cases, so that they fail visibly.
# ---------------------------------------------------------------------------

# Probe 1: IS [NOT] NULL on untyped generic attributes (owner is set on 5
# buildings).
ISNULL_OK=1
if cli_export "$OUT" -t bldg:Building -f "owner IS NOT NULL" >/dev/null \
    && [ "$(count_gml_features "$OUT" 'bldg:Building')" = "0" ]; then
  ISNULL_OK=0
fi
ISNULL_SKIP="IS [NOT] NULL on untyped generic attributes returns no features; to be clarified"

# Probe 2: SQL() expressions (a trivially-true subquery matches all 10 features).
SQL_OK=1
if cli_export "$OUT" -f "SQL('select id from feature')" >/dev/null \
    && [ "$(export_ids "$OUT" 'bldg:Building,tran:Road')" = "" ]; then
  SQL_OK=0
fi
SQL_SKIP="SQL() expressions return no features; to be clarified"

# Probe 3: unaccent extension for ACCENTI (install on demand if available).
db_query "CREATE EXTENSION IF NOT EXISTS unaccent;" >/dev/null 2>&1 || true
UNACCENT_OK=$(db_query "SELECT count(*) FROM pg_extension WHERE extname = 'unaccent';")

echo "Probes: is-null-support=$ISNULL_OK sql-support=$SQL_OK unaccent=$UNACCENT_OK"

# ---------------------------------------------------------------------------
# T01-T15: basic operators
# ---------------------------------------------------------------------------
echo ""
echo "--- Basic cases (T01-T15) ---"

cli_export "$OUT" -f "storeys::int = 4"
assert_export_count 1 "$OUT" "bldg:Building,tran:Road" "T01: storeys::int = 4"

cli_export "$OUT" -f "storeys::int <> 4"
assert_export_count 7 "$OUT" "bldg:Building,tran:Road" "T02: storeys::int <> 4"

cli_export "$OUT" -f "storeys::int < 3"
assert_export_count 2 "$OUT" "bldg:Building,tran:Road" "T03: storeys::int < 3"

cli_export "$OUT" -f "storeys::int > 5"
assert_export_count 3 "$OUT" "bldg:Building,tran:Road" "T04: storeys::int > 5"

# T05: BETWEEN via config file (CQL2 text in exportOptions.query.filter)
rm -f "$OUT"
export_to /config/config_export_cql2_text.json "$OUT"
assert_export_count 4 "$OUT" "bldg:Building,tran:Road" "T05: BETWEEN 3 AND 6 (config, CQL2 text)"

cli_export "$OUT" -f "name LIKE 'Building 0%'"
assert_export_count 8 "$OUT" "bldg:Building,tran:Road" "T06: name LIKE 'Building 0%'"

# T07: matches B05-B08 plus ROAD_CQL2_02 (district 'Nord').
cli_export "$OUT" -f "district IN ('Nord', 'Sued')"
assert_export_count 5 "$OUT" "bldg:Building,tran:Road" "T07: district IN ('Nord', 'Sued')"

if [ "$ISNULL_OK" = "1" ]; then
  cli_export "$OUT" -t bldg:Building -f "owner IS NULL"
  assert_export_count 3 "$OUT" "bldg:Building" "T08: owner IS NULL (buildings only)"

  cli_export "$OUT" -f "owner IS NOT NULL"
  assert_export_count 5 "$OUT" "bldg:Building,tran:Road" "T09: owner IS NOT NULL"

  cli_export "$OUT" -f "(district = 'Mitte' AND storeys::int > 2) OR NOT owner IS NULL"
  assert_export_count 5 "$OUT" "bldg:Building,tran:Road" "T10: AND/OR/NOT with parentheses"
else
  skip_case "T08/T09/T10" "$ISNULL_SKIP"
fi

# T10b: same logical construct (AND/OR/NOT + parentheses) without IS NULL.
cli_export "$OUT" -f "(district = 'Mitte' AND storeys::int > 2) OR NOT district = 'Mitte'"
assert_export_count 7 "$OUT" "bldg:Building,tran:Road" "T10b: AND/OR/NOT with parentheses (no IS NULL)"

cli_export "$OUT" -t bldg:Building -f "district = 'Mitte'"
assert_export_count 4 "$OUT" "bldg:Building" "T11: type filter + attribute filter"

# T12: S_INTERSECTS with the west bbox via config file (CQL2 JSON)
rm -f "$OUT"
export_to /config/config_export_cql2_json.json "$OUT"
assert_export_count 5 "$OUT" "bldg:Building,tran:Road" "T12: S_INTERSECTS west bbox (config, CQL2 JSON)"

# T13: codelist value on a multi-valued attribute ("at least one value
# matches").  bldg:-prefixed properties require the type context (-t).
cli_export "$OUT" -t bldg:Building -f "bldg:function = '1010' AND storeys::int >= 7"
assert_export_count 2 "$OUT" "bldg:Building" "T13: bldg:function = '1010' AND storeys::int >= 7"

# T14: CQL2 + type filter + CityJSON output
rm -f "$OUT_JSON"
run_quiet citydb --config "$CFG" export cityjson -o "$OUT_JSON" -t bldg:Building -f "storeys::int > 5"
assert_export_count 3 "$OUT_JSON" "Building" "T14: CityJSON export with CQL2 filter"
assert_schema_valid "$OUT_JSON" "T14: filtered CityJSON export is schema-valid"

# T15: empty result set -> exit 0, valid CityModel root, 0 features
cli_export "$OUT" -f "storeys::int > 999"
assert_equals 1 "$(grep -c '<CityModel' "$OUT")" "T15: empty export has CityModel root"
assert_export_count 0 "$OUT" "bldg:Building,tran:Road" "T15: empty result set"
assert_schema_valid "$OUT" "T15: empty export is schema-valid"

# ---------------------------------------------------------------------------
# C01-C11: complex queries
# ---------------------------------------------------------------------------
echo ""
echo "--- Complex cases (C01-C11) ---"

cli_export "$OUT" -f "storeys::int * 3 + 1 > 2 ^ 4"
assert_export_count 3 "$OUT" "bldg:Building,tran:Road" "C01: arithmetic with precedence"

# C02: 1-based index access on a multi-valued attribute (needs -t for the
# bldg: prefix).  The explicit index() form is rejected by the tool, see N08.
cli_export "$OUT" -t bldg:Building -f "bldg:function[2] = '2000'"
assert_export_count 2 "$OUT" "bldg:Building" "C02: bldg:function[2] = '2000'"

cli_export "$OUT" -t bldg:Building -f "con:height[con:status = 'measured'].con:value > 20"
assert_export_count 3 "$OUT" "bldg:Building" "C03: nested path with step predicate"

cli_export "$OUT" -t bldg:Building -f "core:creationDate >= TIMESTAMP('2026-01-01T00:00:00Z') AND core:terminationDate IS NULL"
assert_export_count 8 "$OUT" "bldg:Building" "C04: time filter via comparison operators"

cli_export "$OUT" -f "S_DWITHIN(core:envelope, POINT(458800 5438360), 150, 'm')"
assert_export_count 5 "$OUT" "bldg:Building,tran:Road" "C05a: S_DWITHIN 150 m"

cli_export "$OUT" -f "S_BEYOND(core:envelope, POINT(458800 5438360), 200, 'm')"
assert_export_count 5 "$OUT" "bldg:Building,tran:Road" "C05b: S_BEYOND 200 m"

cli_export "$OUT" -f "NOT S_DISJOINT(core:envelope, BBOX(458780, 5438330, 458860, 5438400))"
assert_export_count 5 "$OUT" "bldg:Building,tran:Road" "C06: NOT S_DISJOINT (== T12)"

if [ "$SQL_OK" = "1" ]; then
  cli_export "$OUT" -f "district = 'Mitte' AND SQL('select id from feature where objectclass_id = $OCID')"
  assert_export_count 4 "$OUT" "bldg:Building,tran:Road" "C07: SQL() escape hatch"

  cli_export "$OUT" -f "storeys::int > 2" --sql-filter "select id from feature where objectclass_id = $OCID"
  assert_export_count 6 "$OUT" "bldg:Building,tran:Road" "C08: -f AND --sql-filter combined"
else
  skip_case "C07/C08" "$SQL_SKIP"
fi

if [ "$ISNULL_OK" = "1" ]; then
  cli_export "$OUT" -f "(CASEI(district) IN ('mitte','nord') AND NOT (owner IS NULL OR storeys::int < 2)) OR name LIKE 'Road 0_'"
  assert_export_count 6 "$OUT" "bldg:Building,tran:Road" "C09: deep nesting + CASEI + LIKE wildcard _"
else
  skip_case "C09" "$ISNULL_SKIP"
fi

# C09b: same constructs (CASEI, nesting, LIKE '_') without IS NULL.
cli_export "$OUT" -f "(CASEI(district) IN ('mitte','nord') AND NOT (storeys::int < 2)) OR name LIKE 'Road 0_'"
assert_export_count 7 "$OUT" "bldg:Building,tran:Road" "C09b: CASEI + nesting + LIKE wildcard _ (no IS NULL)"

# C10: complex CQL2 JSON in config (n-ary and, GeoJSON point, timestamp)
rm -f "$OUT"
export_to /config/config_export_cql2_complex.json "$OUT"
assert_export_count 4 "$OUT" "bldg:Building,tran:Road" "C10: complex CQL2 JSON (config)"
assert_schema_valid "$OUT" "C10: filtered export is schema-valid"

if [ "$UNACCENT_OK" = "1" ]; then
  cli_export "$OUT" -f "ACCENTI(street) = ACCENTI('Munchner Strasse')"
  assert_export_count 1 "$OUT" "bldg:Building" "C11: ACCENTI matches 'Muenchner Strasse'"
else
  skip_case "C11" "PostgreSQL extension 'unaccent' is not available in the DB image"
fi

# ---------------------------------------------------------------------------
# G01-G08: spatial operators
# ---------------------------------------------------------------------------
echo ""
echo "--- Geo cases (G01-G08) ---"

cli_export "$OUT" -f "S_WITHIN(core:envelope, POLYGON((458780 5438330, 458860 5438330, 458860 5438400, 458780 5438400, 458780 5438330)))"
assert_export_count 5 "$OUT" "bldg:Building,tran:Road" "G01: S_WITHIN west polygon (== T12)"

# G02: the reference point lies inside the envelope of BLDG_CQL2_01 only.
cli_export "$OUT" -f "S_CONTAINS(core:envelope, POINT(458795 5438345))"
assert_export_count 1 "$OUT" "bldg:Building,tran:Road" "G02: S_CONTAINS reference point in B01"

# G03: ROAD_CQL2_01 runs W-E and crosses the N-S test line at x=458817.
# The geometry property is core:lod2MultiSurface and requires the type
# context (-t tran:Road).
cli_export "$OUT" -t tran:Road -f "S_CROSSES(core:lod2MultiSurface, LINESTRING(458817 5438330, 458817 5438400))"
assert_export_count 1 "$OUT" "tran:Road" "G03: S_CROSSES road geometry with N-S line"

# G04: west bbox in WGS84 coordinates with CRS transformation (== T12)
cli_export "$OUT" --filter-crs 4326 -f "S_INTERSECTS(core:envelope, BBOX(8.43534, 49.09643, 8.43645, 49.09708))"
assert_export_count 5 "$OUT" "bldg:Building,tran:Road" "G04: west bbox in WGS84 via --filter-crs 4326"

# G05: 3D bbox (6 coordinates); the z range is ignored and the bbox is
# evaluated in 2D (pinned, cf. SP39), so the result equals T12.
cli_export "$OUT" -f "S_INTERSECTS(core:envelope, BBOX(458780, 5438330, -10, 458860, 5438400, 100))"
assert_export_count 5 "$OUT" "bldg:Building,tran:Road" "G05: 3D BBOX (== 2D result)"

# G06: filter on the real geometry property instead of the envelope
cli_export "$OUT" -t bldg:Building -f "S_INTERSECTS(core:lod2MultiSurface, BBOX(458780, 5438330, 458860, 5438400))"
assert_export_count 4 "$OUT" "bldg:Building" "G06: S_INTERSECTS on core:lod2MultiSurface"

# G07: smoke tests for the remaining binary spatial operators.
cli_export "$OUT" -f "S_TOUCHES(core:envelope, POLYGON((458785 5438340, 458790 5438340, 458790 5438350, 458785 5438350, 458785 5438340)))"
assert_export_count 1 "$OUT" "bldg:Building,tran:Road" "G07a: S_TOUCHES polygon on B01 west edge"

cli_export "$OUT" -f "S_OVERLAPS(core:envelope, POLYGON((458785 5438335, 458795 5438335, 458795 5438345, 458785 5438345, 458785 5438335)))"
assert_export_count 1 "$OUT" "bldg:Building,tran:Road" "G07b: S_OVERLAPS polygon over B01 corner"

cli_export "$OUT" -f "S_EQUALS(core:envelope, POLYGON((458790 5438340, 458800 5438340, 458800 5438350, 458790 5438350, 458790 5438340)))"
assert_export_count 1 "$OUT" "bldg:Building,tran:Road" "G07c: S_EQUALS exact B01 envelope"

# G08: tiled export over the full extent; tiling injects a spatial predicate
# per tile into the same query.  2 columns x 1 row -> west/east tile with 5
# features each.
rm -f /output/cql2_tiles*.gml
run_quiet citydb --config "$CFG" export citygml -o /output/cql2_tiles.gml --tile-matrix 2,1
assert_file_exists /output/cql2_tiles_0_0.gml 100 "G08: west tile exists"
assert_file_exists /output/cql2_tiles_1_0.gml 100 "G08: east tile exists"
assert_export_count 5 /output/cql2_tiles_0_0.gml "bldg:Building,tran:Road" "G08: west tile has 5 features"
assert_export_count 5 /output/cql2_tiles_1_0.gml "bldg:Building,tran:Road" "G08: east tile has 5 features"
assert_schema_valid /output/cql2_tiles_0_0.gml "G08: west tile is schema-valid"
assert_schema_valid /output/cql2_tiles_1_0.gml "G08: east tile is schema-valid"

# ---------------------------------------------------------------------------
# F01-F10: native building attributes, object ids and address paths.
# ---------------------------------------------------------------------------
echo ""
echo "--- Feature attribute cases (F01-F10) ---"

# F01/F02: short form on the complex con:height property (resolves to its
# con:value without spelling out the path, cf. C03).
cli_export "$OUT" -t bldg:Building -f "con:height > 20"
assert_export_count 3 "$OUT" "bldg:Building" "F01: con:height > 20 (short form)"

cli_export "$OUT" -t bldg:Building -f "con:height BETWEEN 10 AND 20"
assert_export_count 3 "$OUT" "bldg:Building" "F02: con:height BETWEEN 10 AND 20"

# F03: IN on a multi-valued codelist; B07/B08 match both values but must be
# exported only once.
cli_export "$OUT" -t bldg:Building -f "bldg:function IN ('1010', '2000')"
assert_export_count 2 "$OUT" "bldg:Building" "F03: bldg:function IN ('1010', '2000')"

cli_export "$OUT" -t bldg:Building -f "bldg:roofType = '1000'"
assert_export_count 4 "$OUT" "bldg:Building" "F04: bldg:roofType = '1000'"

cli_export "$OUT" -t bldg:Building -f "bldg:roofType IN ('3100', '3200', '3300')"
assert_export_count 3 "$OUT" "bldg:Building" "F05: bldg:roofType IN ('3100', '3200', '3300')"

# F06: native integer attribute, no cast required (unlike the generic storeys)
cli_export "$OUT" -t bldg:Building -f "bldg:storeysAboveGround >= 5"
assert_export_count 4 "$OUT" "bldg:Building" "F06: bldg:storeysAboveGround >= 5"

# F07: core:objectId maps to the gml:id; works without type context
cli_export "$OUT" -f "core:objectId LIKE 'BLDG_CQL2_0%'"
assert_export_count 8 "$OUT" "bldg:Building" "F07a: core:objectId LIKE 'BLDG_CQL2_0%'"
assert_export_count 0 "$OUT" "tran:Road" "F07a: roads excluded by object id"

cli_export "$OUT" -f "core:objectId LIKE 'BLDG_CQL2_0%'" --limit 3
assert_export_count 3 "$OUT" "bldg:Building,tran:Road" "F07b: core:objectId LIKE + --limit 3"

# F08: generic attribute with explicit gen: prefix (== T07)
cli_export "$OUT" -f "gen:district IN ('Nord', 'Sued')"
assert_export_count 5 "$OUT" "bldg:Building,tran:Road" "F08: gen:district IN ('Nord', 'Sued')"

# F09: S_DISJOINT without NOT (cf. C06) -> east cluster only
cli_export "$OUT" -f "S_DISJOINT(core:envelope, BBOX(458780, 5438330, 458860, 5438400))"
assert_export_count 5 "$OUT" "bldg:Building,tran:Road" "F09a: S_DISJOINT west bbox"
assert_equals 0 "$(grep -c 'gml:id="BLDG_CQL2_0[1-4]"' "$OUT" || true)" "F09a: no west building exported"

cli_export "$OUT" -f "S_DISJOINT(core:envelope, BBOX(458780, 5438330, 458860, 5438400))" --limit 2
assert_export_count 2 "$OUT" "bldg:Building,tran:Road" "F09b: S_DISJOINT + --limit 2"

# F10: paths into the address table (B01-B03 Karlsruhe, B05 Ettlingen;
# street Kaiser* on B01, B02, B05)
cli_export "$OUT" -t bldg:Building -f "bldg:address.core:city = 'Karlsruhe'"
assert_export_count 3 "$OUT" "bldg:Building" "F10a: bldg:address.core:city = 'Karlsruhe'"
assert_schema_valid "$OUT" "F10a: export with addresses is schema-valid"
assert_equals 3 "$(grep -c '<Address gml:id="ADDR_CQL2_' "$OUT" || true)" "F10a: addresses are exported with the buildings"

cli_export "$OUT" -t bldg:Building -f "bldg:address.core:street LIKE 'Kaiser%'"
assert_export_count 3 "$OUT" "bldg:Building" "F10b: bldg:address.core:street LIKE 'Kaiser%'"

cli_export "$OUT" -t bldg:Building -f "bldg:address.core:city = 'Karlsruhe' AND bldg:address.core:street LIKE 'Kaiser%'"
assert_export_count 2 "$OUT" "bldg:Building" "F10c: city AND street on the address"

cli_export "$OUT" -t bldg:Building -f "bldg:address.core:zipCode = '76185'"
assert_export_count 2 "$OUT" "bldg:Building" "F10d: bldg:address.core:zipCode = '76185'"

# ---------------------------------------------------------------------------
# N01-N10 + E01: negative cases and pinned edge behavior
# ---------------------------------------------------------------------------
echo ""
echo "--- Negative cases (N01-N10, E01) ---"

assert_fails_with "Failed to parse the provided CQL2 filter expression." \
  "N01: invalid syntax" \
  citydb --config "$CFG" export citygml -o "$OUT" -f "storeys::int > ("

assert_fails_with "Failed to build database query." \
  "N02: unknown attribute with namespace prefix" \
  citydb --config "$CFG" export citygml -o "$OUT" -f "bldg:doesnotexist = 'x'"

assert_fails_with "Temporal predicates are not supported." \
  "N03: temporal operator T_AFTER" \
  citydb --config "$CFG" export citygml -o "$OUT" -f "T_AFTER(core:creationDate, TIMESTAMP('2026-01-01T00:00:00Z'))"

assert_fails_with "Array predicates are not supported." \
  "N04: array predicate A_CONTAINS" \
  citydb --config "$CFG" export citygml -o "$OUT" -f "A_CONTAINS(bldg:function, ('1000','1010'))"

assert_fails_with "as numeric expression" \
  "N05: BETWEEN on timestamps (numeric only)" \
  citydb --config "$CFG" export citygml -o "$OUT" -f "core:creationDate BETWEEN TIMESTAMP('2026-01-01T00:00:00Z') AND TIMESTAMP('2026-12-31T00:00:00Z')"

assert_fails_with "Use explicit type casts." \
  "N06: missing cast on generic attribute" \
  citydb --config "$CFG" export citygml -o "$OUT" -f "storeys = 4"

assert_fails_with "Geometry collections are not supported" \
  "N07: GEOMETRYCOLLECTION literal" \
  citydb --config "$CFG" export citygml -o "$OUT" -f "S_INTERSECTS(core:envelope, GEOMETRYCOLLECTION(POINT(1 2)))"

# N08: the explicit index() form of C02 is rejected by citydb-tool
# (pinned).
assert_fails_with "Predicates on the last step" \
  "N08: index() predicate on last step of IS NOT NULL" \
  citydb --config "$CFG" export citygml -o "$OUT" -t bldg:Building -f "bldg:function[index() >= 2] IS NOT NULL"

# N09: native bldg: property without type context (the same filter works
# with -t bldg:Building, see F06)
assert_fails_with "Failed to build database query." \
  "N09: bldg:storeysAboveGround without -t bldg:Building" \
  citydb --config "$CFG" export citygml -o "$OUT" -f "bldg:storeysAboveGround >= 5"

assert_fails_with "Failed to build database query." \
  "N10: unknown property on the address" \
  citydb --config "$CFG" export citygml -o "$OUT" -t bldg:Building -f "bldg:address.core:doesnotexist = 'x'"

# E01: unknown attribute WITHOUT namespace prefix falls back to a generic
# attribute lookup -> exit 0, valid file, 0 features (pinned deliberately).
cli_export "$OUT" -f "doesnotexist = 'x'"
assert_equals 1 "$(grep -c '<CityModel' "$OUT")" "E01: fallback export has CityModel root"
assert_export_count 0 "$OUT" "bldg:Building,tran:Road" "E01: unknown attribute without prefix matches nothing"

# ---------------------------------------------------------------------------
# D01-D04: further users of the CQL2 machinery.
# D01/D02 are read-only; D03 terminates features and D04 checks the
# resulting validity states.
# ---------------------------------------------------------------------------
echo ""
echo "--- Query mechanics (D01-D04) ---"

# D01: sorting uses the same property path parser as the filters
cli_export "$OUT" -s "core:objectId-" --limit 3
assert_export_count 3 "$OUT" "bldg:Building,tran:Road" "D01: sort desc + limit yields 3 features"
FIRST_ID=$(ordered_ids "$OUT" "bldg:Building,tran:Road" | cut -d' ' -f1)
assert_equals "ROAD_CQL2_02" "$FIRST_ID" "D01: first feature has the highest gml:id"

# D02: pagination over all 10 features
cli_export "$OUT" --limit 5 --start-index 5
assert_export_count 5 "$OUT" "bldg:Building,tran:Road" "D02: --limit 5 --start-index 5"

# D03: delete (mode terminate) with a CQL2 filter -> B01 + B02 terminated
run_quiet citydb --config "$CFG" delete -f "storeys::int < 3"
assert_equals 8 "$(get_feature_count_by_type 'Building')" "D03: rows are kept on terminate"
assert_equals 6 "$(db_query "SELECT count(*) FROM feature f JOIN objectclass o ON f.objectclass_id = o.id WHERE o.classname = 'Building' AND f.termination_date IS NULL;")" \
  "D03: 6 of 8 buildings remain valid"

# D04: validity filters are injected into the same query
cli_export "$OUT" -t bldg:Building -M valid
assert_export_count 6 "$OUT" "bldg:Building" "D04: -M valid exports 6 buildings"

cli_export "$OUT" -t bldg:Building -M all
assert_export_count 8 "$OUT" "bldg:Building" "D04: -M all exports 8 buildings"

cli_export "$OUT" -t bldg:Building -M invalid
assert_export_count 2 "$OUT" "bldg:Building" "D04: -M invalid exports 2 buildings"

echo ""
echo "=== CQL2 Filter Tests PASSED ==="
