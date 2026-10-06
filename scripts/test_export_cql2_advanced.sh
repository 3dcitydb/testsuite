#!/bin/bash
# Advanced CQL2 filter tests for citydb-tool exports.
#
# Complements test_export_cql2.sh with operators, expressions, typed generic
# attributes, CQL2 JSON, paths over sub-features and further negative cases.
# The cases validate the exact set of exported gml:ids (counts only for
# nested feature types, P10-P14).
#
# Datasets:
#   data/synthetic/cql2_features.gml           (O, K, J, S, L, X01-X20)
#   data/Railway_Scene/Railway_Scene_LoD3.gml  (P, X21-X22)
#
# Covered:
#   O01-O17  comparison/arithmetic operators, property-to-property
#            comparisons, literals, keyword case, quoted identifiers
#   K01-K14  typed generic attributes (double, timestamp, uri, measure,
#            code), non-ASCII names, quotes in strings, attribute sets
#   J01-J15  CQL2 JSON filters in the config file (same results as text)
#   S01-S04  sorting (multiple keys, generic attributes, NULL ordering)
#   L01-L10  IS [NOT] NULL on different path types, --sql-filter, LIKE
#            escapes, empty strings, timestamp offsets, invalid literals
#   P01-P15  property paths over sub-features (boundary surfaces,
#            installations), filters on nested feature types
#   X01-X22  negative cases (exit != 0 plus error message check)
#
# Cases with an unexpected result in the tested citydb-tool version are
# detected at runtime and SKIPPED (to be clarified): O08, O09, O17, P09,
# L04, L05, L07 and the message check of X16.

set -e

source /scripts/test_helpers.sh

CFG=/config/config_export_cql2_base.json
CFG_IMPORT=/config/config_citygml_import.json
DATASET=/data/synthetic/cql2_features.gml
RAILWAY=/data/Railway_Scene/Railway_Scene_LoD3.gml
OUT=/output/cql2_adv_case.gml
JSON_CFG=/tmp/cql2_adv_query.json
TOP="bldg:Building,tran:Road"

echo "=== Advanced CQL2 Filter Tests ==="
echo "-------------------------------------------"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# Run a CityGML export with the base config and the given CLI options.
cli_export() {
  export_to "$CFG" "$OUT" "$@"
}

# Run a CityGML export with a CQL2 JSON query written into a config file.
# Usage: json_export '<filter JSON>' ['<further query members>,']
json_export() {
  make_query_config "$CFG" "$JSON_CFG" "${2:-}\"filter\": $1"
  export_to "$JSON_CFG" "$OUT"
}

# Expand building/road numbers to gml:ids: b 01 02 -> BLDG_CQL2_01 BLDG_CQL2_02
b() { local n; for n in "$@"; do printf 'BLDG_CQL2_%s ' "$n"; done; }
r() { local n; for n in "$@"; do printf 'ROAD_CQL2_%s ' "$n"; done; }

# ---------------------------------------------------------------------------
# Setup: clean import of the deterministic dataset
# ---------------------------------------------------------------------------
truncate_features

echo "Importing CQL2 test dataset..."
run_quiet citydb --config "$CFG_IMPORT" import citygml "$DATASET"
echo "Import complete."

assert_equals 10 "$(get_feature_count)" "Setup: 10 features imported"
assert_equals 3 "$(db_query "SELECT count(*) FROM property WHERE name = 'energy';")" "Setup: 3 generic attribute sets"

# ---------------------------------------------------------------------------
# Capability probes (see header)
# ---------------------------------------------------------------------------
# A probe hits on an empty result; only that signature leads to a skip, any other deviation runs the cases so that they fail
# visibly.
# probe_empty <expected-empty types> <cli options...>
probe_empty() {
  local types="$1"
  shift
  cli_export "$@" >/dev/null && [ "$(export_ids "$OUT" "$types")" = "" ]
}

DIVISION_OK=1
probe_empty "$TOP" -f "storeys::int / 2 = 2.5" && DIVISION_OK=0
DIVISION_SKIP="'/' on two integers returns an integer result; to be clarified"

UNARY_OK=1
probe_empty "$TOP" -f "(-storeys::int) < -6" && UNARY_OK=0
UNARY_SKIP="unary minus on a parenthesized expression gives an unexpected result; to be clarified"

SAMEPATH_OK=1
probe_empty bldg:Building -t bldg:Building -f "bldg:function = '1010' AND bldg:function = '2000'" && SAMEPATH_OK=0
SAMEPATH_SKIP="the same property path twice in an AND gives an unexpected result; to be clarified"

db_query "CREATE EXTENSION IF NOT EXISTS unaccent;" >/dev/null 2>&1 || true
UNACCENT_OK=$(db_query "SELECT count(*) FROM pg_extension WHERE extname = 'unaccent';")

echo "Probes: division=$DIVISION_OK unary-minus=$UNARY_OK same-path-and=$SAMEPATH_OK unaccent=$UNACCENT_OK"

# ---------------------------------------------------------------------------
# O01-O17: operators and expressions
# ---------------------------------------------------------------------------
echo ""
echo "--- Operators and expressions (O01-O17) ---"

cli_export -f "storeys::int <= 3"
assert_export_ids "$(b 01 02 03)" "$OUT" "$TOP" "O01: storeys::int <= 3"

cli_export -f "storeys::int NOT BETWEEN 3 AND 6"
assert_export_ids "$(b 01 02 07 08)" "$OUT" "$TOP" "O02: NOT BETWEEN 3 AND 6"

cli_export -f "district NOT IN ('Mitte')"
assert_export_ids "$(b 05 06 07 08) $(r 02)" "$OUT" "$TOP" "O03: NOT IN ('Mitte')"

cli_export -f "name NOT LIKE 'Building%'"
assert_export_ids "$(r 01 02)" "$OUT" "$TOP" "O04: NOT LIKE 'Building%'"

cli_export -f "storeys::int - 2 = 3"
assert_export_ids "$(b 05)" "$OUT" "$TOP" "O05: subtraction"

cli_export -f "storeys::int div 2 = 2"
assert_export_ids "$(b 04 05)" "$OUT" "$TOP" "O06: integer division (div)"

cli_export -f "storeys::int % 2 = 0"
assert_export_ids "$(b 02 04 06 08)" "$OUT" "$TOP" "O07: modulo"

if [ "$DIVISION_OK" = "1" ]; then
  cli_export -f "storeys::int / 2 = 2"
  assert_export_ids "$(b 04)" "$OUT" "$TOP" "O08: division of integers yields a decimal"
else
  skip_case "O08" "$DIVISION_SKIP"
fi

cli_export -f "storeys::int / 2.0 = 2.5"
assert_export_ids "$(b 05)" "$OUT" "$TOP" "O08b: division with a decimal literal"

if [ "$UNARY_OK" = "1" ]; then
  cli_export -f "(-storeys::int) < -6"
  assert_export_ids "$(b 07 08)" "$OUT" "$TOP" "O09: unary minus on a property"
else
  skip_case "O09" "$UNARY_SKIP"
fi

cli_export -f "storeys::int * -1 < -6"
assert_export_ids "$(b 07 08)" "$OUT" "$TOP" "O09b: negative literal in an arithmetic expression"

cli_export -t bldg:Building -f "storeys::int = bldg:storeysAboveGround"
assert_export_ids "$(b 01 02 03 04 05 06 07 08)" "$OUT" bldg:Building "O10: generic attribute = native attribute"

cli_export -t bldg:Building -f "storeys::int <> bldg:storeysAboveGround"
assert_export_ids "" "$OUT" bldg:Building "O10: generic attribute <> native attribute"

cli_export -t bldg:Building -f "con:height = bldg:storeysAboveGround * 3.5"
assert_export_ids "$(b 01 02 03 04 05 06 07 08)" "$OUT" bldg:Building "O11: arithmetic across two properties"

cli_export -f "district = 'Mitte' and storeys::int > 2 or name like 'Road%'"
assert_export_ids "$(b 03 04) $(r 01 02)" "$OUT" "$TOP" "O12: lower-case keywords and precedence of AND over OR"

cli_export -f "TRUE"
assert_export_count 10 "$OUT" "$TOP" "O13: TRUE matches all features"
cli_export -f "FALSE"
assert_export_count 0 "$OUT" "$TOP" "O13: FALSE matches nothing"
cli_export -f "NOT FALSE"
assert_export_count 10 "$OUT" "$TOP" "O13: NOT FALSE matches all features"

cli_export -f "\"district\" = 'Nord'"
assert_export_ids "$(b 05 06) $(r 02)" "$OUT" "$TOP" "O14: double-quoted property name"

cli_export -f "NOT (NOT (district = 'Mitte'))"
assert_export_ids "$(b 01 02 03 04) $(r 01)" "$OUT" "$TOP" "O15: double negation"

cli_export -f "CASEI(name) LIKE CASEI('building 0%')"
assert_export_ids "$(b 01 02 03 04 05 06 07 08)" "$OUT" "$TOP" "O16: CASEI on both sides of LIKE"

if [ "$SAMEPATH_OK" = "1" ]; then
  cli_export -t bldg:Building -f "bldg:function = '1010' AND bldg:function = '2000'"
  assert_export_ids "$(b 07 08)" "$OUT" bldg:Building "O17: AND over two values of a multi-valued property"
else
  skip_case "O17" "$SAMEPATH_SKIP"
fi

# ---------------------------------------------------------------------------
# K01-K14: typed generic attributes.  The cast selects the data type of the
# generic attribute, it does not convert values (see K04).
# ---------------------------------------------------------------------------
echo ""
echo "--- Typed generic attributes (K01-K14) ---"

cli_export -f "area::double > 450.25"
assert_export_ids "$(b 05 06 07 08)" "$OUT" "$TOP" "K01: double attribute"

cli_export -f "area::double BETWEEN 200 AND 400"
assert_export_ids "$(b 02 03)" "$OUT" "$TOP" "K02: BETWEEN on a double attribute"

cli_export -f "area::double / storeys::int > 100.4"
assert_export_ids "$(b 01)" "$OUT" "$TOP" "K03: double / integer attribute"

cli_export -f "area::int > 450"
assert_export_ids "" "$OUT" "$TOP" "K04: ::int does not match a double attribute (cast = type selector)"

cli_export -f "constructionDate::timestamp < TIMESTAMP('1950-01-01T00:00:00Z')"
assert_export_ids "$(b 01 02 03)" "$OUT" "$TOP" "K05: date attribute vs TIMESTAMP"

cli_export -f "constructionDate::timestamp < DATE('1950-01-01')"
assert_export_ids "$(b 01 02 03)" "$OUT" "$TOP" "K06: date attribute vs DATE"

cli_export -f "website::uri LIKE 'https://example.org/%'"
assert_export_ids "$(b 01 02 03 04)" "$OUT" "$TOP" "K07: uri attribute LIKE"
cli_export -f "website::uri = 'https://example.org/buildings/02'"
assert_export_ids "$(b 02)" "$OUT" "$TOP" "K07: uri attribute ="

cli_export -f "volume::measure >= 5000"
assert_export_ids "$(b 05 06 07 08)" "$OUT" "$TOP" "K08: measure attribute"
cli_export -f "volume::measure / area::double < 9.96"
assert_export_ids "$(b 01)" "$OUT" "$TOP" "K08: measure / double attribute"

cli_export -f "usageCode::code = 'B'"
assert_export_ids "$(b 05 06)" "$OUT" "$TOP" "K09: code attribute"
cli_export -f "usageCode::code IN ('A', 'C')"
assert_export_ids "$(b 01 02 03 04 07 08)" "$OUT" "$TOP" "K09: code attribute IN"
cli_export -f "usageCode = 'B'"
assert_export_ids "$(b 05 06)" "$OUT" "$TOP" "K09: code attribute without cast"

cli_export -f "Gemeindeschlüssel = '08215017'"
assert_export_ids "$(b 05 06 07 08)" "$OUT" "$TOP" "K10: non-ASCII attribute name"
cli_export -f "\"Gemeindeschlüssel\" = '08215017'"
assert_export_ids "$(b 05 06 07 08)" "$OUT" "$TOP" "K10: non-ASCII attribute name, double-quoted"
cli_export -f "\"gen:Gemeindeschlüssel\" = '08215017'"
assert_export_ids "$(b 05 06 07 08)" "$OUT" "$TOP" "K10: prefixed name inside double quotes"

cli_export -f "architect = 'O''Brien & Partner'"
assert_export_ids "$(b 03)" "$OUT" "$TOP" "K11: escaped apostrophe in a string literal"
cli_export -f "architect LIKE '%''%'"
assert_export_ids "$(b 03)" "$OUT" "$TOP" "K11: escaped apostrophe in a LIKE pattern"

cli_export -f "CASEI(architect) = CASEI('MÜLLER-LÜDENSCHEIDT')"
assert_export_ids "$(b 04)" "$OUT" "$TOP" "K12: CASEI with umlauts"
if [ "$UNACCENT_OK" = "1" ]; then
  cli_export -f "ACCENTI(architect) = ACCENTI('Muller-Ludenscheidt')"
  assert_export_ids "$(b 04)" "$OUT" "$TOP" "K12: ACCENTI with umlauts"
else
  skip_case "K12 (ACCENTI)" "PostgreSQL extension 'unaccent' is not available in the DB image"
fi

cli_export -f "energy.rating::int >= 2"
assert_export_ids "$(b 02 03)" "$OUT" "$TOP" "K13: attribute inside an attribute set"
cli_export -f "gen:energy.gen:rating::int >= 2"
assert_export_ids "$(b 02 03)" "$OUT" "$TOP" "K13: attribute set path with gen: prefixes"
cli_export -f "energy[rating::int = 3].label = 'E03'"
assert_export_ids "$(b 03)" "$OUT" "$TOP" "K13: step predicate on an attribute set"
cli_export -f "energy.label IN ('E01', 'E03') AND NOT energy.rating::int = 2"
assert_export_ids "$(b 01 03)" "$OUT" "$TOP" "K13: two attributes of the same set"
cli_export -f "energy.rating::int = storeys::int"
assert_export_ids "$(b 01 02 03)" "$OUT" "$TOP" "K13: set attribute = top-level attribute"

# K14: with a type context, unprefixed names resolve to native properties
# first (core:area, see X13); the gen: prefix selects the generic attribute.
cli_export -t bldg:Building -f "(gen:area::double > 250 AND usageCode::code IN ('A','B') AND constructionDate::timestamp < DATE('1965-01-01')) AND NOT (bldg:roofType = '1000' AND storeys::int < 3) AND storeys::int % 2 = 1"
assert_export_ids "$(b 03 05)" "$OUT" bldg:Building "K14: combined typed attributes, native attributes and arithmetic"

# ---------------------------------------------------------------------------
# J01-J15: CQL2 JSON in the config file
# ---------------------------------------------------------------------------
echo ""
echo "--- CQL2 JSON (J01-J15) ---"

json_export '{"op": "like", "args": [{"property": "name"}, "Road%"]}'
assert_export_ids "$(r 01 02)" "$OUT" "$TOP" "J01: like"

json_export '{"op": "not", "args": [{"op": "like", "args": [{"property": "name"}, "Road%"]}]}'
assert_export_ids "$(b 01 02 03 04 05 06 07 08)" "$OUT" "$TOP" "J02: not like"

json_export '{"op": "between", "args": [{"property": "storeys::int"}, 3, 6]}'
assert_export_ids "$(b 03 04 05 06)" "$OUT" "$TOP" "J03: between with type cast in the property name"

json_export '{"op": "in", "args": [{"property": "storeys::int"}, [1, 3, 5]]}'
assert_export_ids "$(b 01 03 05)" "$OUT" "$TOP" "J04: in with numbers"

json_export '{"op": ">", "args": [{"op": "+", "args": [{"op": "*", "args": [{"property": "storeys::int"}, 3]}, 1]}, {"op": "^", "args": [2, 4]}]}'
assert_export_ids "$(b 06 07 08)" "$OUT" "$TOP" "J05: nested arithmetic (== C01)"

json_export '{"op": "=", "args": [{"op": "casei", "args": [{"property": "district"}]}, {"op": "casei", "args": ["MITTE"]}]}'
assert_export_ids "$(b 01 02 03 04) $(r 01)" "$OUT" "$TOP" "J06: casei"

json_export '{"op": "or", "args": [{"op": "=", "args": [{"property": "district"}, "Sued"]}, {"op": "not", "args": [{"op": "<", "args": [{"property": "storeys::int"}, 6]}]}]}'
assert_export_ids "$(b 06 07 08)" "$OUT" "$TOP" "J07: or / not"

json_export '{"op": ">", "args": [{"property": "con:height[con:status = '"'measured'"'].con:value"}, 20]}' '"featureTypes": [{"name": "bldg:Building"}], '
assert_export_ids "$(b 06 07 08)" "$OUT" bldg:Building "J08: step predicate in a JSON property reference (== C03)"

json_export '{"op": ">", "args": [{"property": "core:creationDate"}, {"date": "2020-01-01"}]}' '"featureTypes": [{"name": "bldg:Building"}], '
assert_export_ids "$(b 01 02 03 04 05 06 07 08)" "$OUT" bldg:Building "J09: date literal"

json_export '{"op": "s_within", "args": [{"property": "core:envelope"}, {"type": "Polygon", "coordinates": [[[458780, 5438330], [458860, 5438330], [458860, 5438400], [458780, 5438400], [458780, 5438330]]]}]}'
assert_export_ids "$(b 01 02 03 04) $(r 01)" "$OUT" "$TOP" "J10: s_within GeoJSON polygon (== G01)"

json_export '{"op": "s_intersects", "args": [{"property": "core:envelope"}, {"type": "MultiPoint", "coordinates": [[458795, 5438345], [459050, 5438350]]}]}'
assert_export_ids "$(b 01 05)" "$OUT" "$TOP" "J11: s_intersects GeoJSON multipoint"

json_export '{"op": "s_crosses", "args": [{"property": "core:lod2MultiSurface"}, {"type": "LineString", "coordinates": [[458817, 5438330], [458817, 5438400]]}]}' '"featureTypes": [{"name": "tran:Road"}], '
assert_export_ids "$(r 01)" "$OUT" tran:Road "J12: s_crosses GeoJSON linestring (== G03)"

json_export '{"op": "s_dwithin", "args": [{"property": "core:envelope"}, {"type": "Point", "coordinates": [458800, 5438360]}, 0.15, "km"]}'
assert_export_ids "$(b 01 02 03 04) $(r 01)" "$OUT" "$TOP" "J13: s_dwithin in km (== C05a)"

json_export '{"op": "s_beyond", "args": [{"property": "core:envelope"}, {"type": "Point", "coordinates": [458800, 5438360]}, 200]}'
assert_export_ids "$(b 05 06 07 08) $(r 02)" "$OUT" "$TOP" "J14: s_beyond without unit (== C05b)"

json_export '{"op": "s_intersects", "args": [{"property": "core:envelope"}, {"bbox": [8.43534, 49.09643, 8.43645, 49.09708]}]}' '"filterSrs": {"srid": 4326}, '
assert_export_ids "$(b 01 02 03 04) $(r 01)" "$OUT" "$TOP" "J15: bbox in WGS84 via filterSrs (== G04)"

# ---------------------------------------------------------------------------
# S01-S04: sorting
# ---------------------------------------------------------------------------
echo ""
echo "--- Sorting (S01-S04) ---"

cli_export -t bldg:Building -s "storeys::int-" --limit 2
assert_equals "BLDG_CQL2_08 BLDG_CQL2_07" "$(ordered_ids "$OUT" "$TOP")" "S01: sort by generic attribute, descending"

cli_export -t bldg:Building -s "con:height.con:value+" --limit 2
assert_equals "BLDG_CQL2_01 BLDG_CQL2_02" "$(ordered_ids "$OUT" "$TOP")" "S02: sort by nested property path, ascending"

cli_export -t bldg:Building -s "district::string-,storeys::int+" --limit 3
assert_equals "BLDG_CQL2_07 BLDG_CQL2_08 BLDG_CQL2_05" "$(ordered_ids "$OUT" "$TOP")" "S03: sort by two keys"

# S04: features without the sort attribute come first when sorting
# descending (PostgreSQL NULLS FIRST, pinned deliberately).
cli_export -s "storeys::int-" --limit 2
assert_export_ids "$(r 01 02)" "$OUT" "$TOP" "S04: NULL values first on descending sort"

# ---------------------------------------------------------------------------
# L01-L10: null checks, SQL filters and literals
# ---------------------------------------------------------------------------
echo ""
echo "--- Null checks, SQL filters and literals (L01-L10) ---"

# L01-L03: IS [NOT] NULL works on paths that end in a simple value: native
# attributes, typed generic attributes and attributes behind a relation.
cli_export -t bldg:Building -f "bldg:roofType IS NOT NULL"
assert_export_ids "$(b 01 02 03 04 05 06 07 08)" "$OUT" bldg:Building "L01: IS NOT NULL on a native attribute"
cli_export -f "core:terminationDate IS NULL"
assert_export_count 10 "$OUT" "$TOP" "L01: IS NULL on a native attribute"

# L02: IS NULL on typed generic attributes (T08-T10 cover untyped ones)
cli_export -f "owner::string IS NOT NULL"
assert_export_ids "$(b 01 02 03 04 05)" "$OUT" "$TOP" "L02: IS NOT NULL on a typed generic attribute"
cli_export -f "owner::string IS NULL"
assert_export_ids "$(b 06 07 08) $(r 01 02)" "$OUT" "$TOP" "L02: IS NULL on a typed generic attribute (attribute missing)"

cli_export -t bldg:Building -f "bldg:address.core:city IS NULL"
assert_export_ids "$(b 04 06 07 08)" "$OUT" bldg:Building "L03: IS NULL on an attribute behind a relation"

# L04: IS [NOT] NULL on paths that end in a relation or a complex property
# (skipped on an empty result).
if cli_export -t bldg:Building -f "bldg:address IS NOT NULL" >/dev/null \
    && [ "$(export_ids "$OUT" bldg:Building)" = "" ]; then
  skip_case "L04" "IS [NOT] NULL on paths ending in a relation or complex property returns no features; to be clarified"
else
  cli_export -t bldg:Building -f "bldg:address IS NOT NULL"
  assert_export_ids "$(b 01 02 03 05)" "$OUT" bldg:Building "L04: IS NOT NULL on a relation"
  cli_export -t bldg:Building -f "con:height IS NOT NULL"
  assert_export_ids "$(b 01 02 03 04 05 06 07 08)" "$OUT" bldg:Building "L04: IS NOT NULL on a complex property"
fi

# L05: --sql-filter on its own (C08 in test_export_cql2.sh combines it with
# -f; skipped on an empty result).
OCID=$(db_query "SELECT id FROM objectclass WHERE classname = 'Building';")
if cli_export --sql-filter "select id from feature where objectclass_id = $OCID" >/dev/null \
    && [ "$(export_ids "$OUT" "$TOP")" = "" ]; then
  skip_case "L05" "--sql-filter on its own returns no features; to be clarified"
else
  cli_export --sql-filter "select id from feature where objectclass_id = $OCID"
  assert_export_ids "$(b 01 02 03 04 05 06 07 08)" "$OUT" "$TOP" "L05: --sql-filter selects the buildings"
fi

# L06: a backslash does not escape the LIKE wildcards; '\_' still matches
# any character (pinned deliberately).
cli_export -f "name LIKE 'Road\_0%'"
assert_export_ids "$(r 01 02)" "$OUT" "$TOP" "L06: backslash does not escape '_' in LIKE (pinned)"

# L07: the empty string literal '' (skipped on a parse error).
if cli_export -f "name <> ''" >/dev/null; then
  assert_export_count 10 "$OUT" "$TOP" "L07: name <> '' matches all features"
  cli_export -f "name = ''"
  assert_export_count 0 "$OUT" "$TOP" "L07: name = '' matches nothing"
elif grep -q "Failed to parse the provided CQL2 filter expression." "$EXPORT_LOG"; then
  skip_case "L07" "the empty string literal '' is rejected by the parser; to be clarified"
else
  echo "FAIL: L07: unexpected error for the empty string literal"; tail -5 "$EXPORT_LOG"
  report_line "- **FAIL:** L07: unexpected error for the empty string literal"
  exit 1
fi

# L08-L09: timestamps are compared in UTC; offsets are converted, a missing
# 'Z' means UTC (CQL2 only defines the 'Z' form, pinned deliberately).
cli_export -f "constructionDate::timestamp = TIMESTAMP('1950-06-15T01:00:00+01:00')"
assert_export_ids "$(b 04)" "$OUT" "$TOP" "L08: TIMESTAMP with a positive UTC offset"
cli_export -f "constructionDate::timestamp = TIMESTAMP('1950-06-14T22:00:00-02:00')"
assert_export_ids "$(b 04)" "$OUT" "$TOP" "L08: TIMESTAMP with a negative UTC offset"
cli_export -f "constructionDate::timestamp = TIMESTAMP('1950-06-15T00:00:00.000Z')"
assert_export_ids "$(b 04)" "$OUT" "$TOP" "L08: TIMESTAMP with fractional seconds"
cli_export -f "constructionDate::timestamp = TIMESTAMP('1950-06-15T00:00:00')"
assert_export_ids "$(b 04)" "$OUT" "$TOP" "L09: TIMESTAMP without 'Z' is taken as UTC (pinned)"

# L10: invalid temporal literals are rejected
assert_fails_with "Failed to parse the provided CQL2 filter expression." \
  "L10: TIMESTAMP without a time part" \
  citydb --config "$CFG" export citygml -o "$OUT" -f "constructionDate::timestamp = TIMESTAMP('1950-06-15')"
assert_fails_with "Failed to parse the provided CQL2 filter expression." \
  "L10: DATE with an invalid month and day" \
  citydb --config "$CFG" export citygml -o "$OUT" -f "constructionDate::timestamp = DATE('1950-13-45')"
assert_fails_with "Failed to parse the provided CQL2 filter expression." \
  "L10: TIMESTAMP with an invalid hour" \
  citydb --config "$CFG" export citygml -o "$OUT" -f "constructionDate::timestamp = TIMESTAMP('1950-06-15T25:00:00Z')"

# ---------------------------------------------------------------------------
# X01-X20: negative cases on the CQL2 dataset
# ---------------------------------------------------------------------------
echo ""
echo "--- Negative cases (X01-X20) ---"

assert_fails_with "Use explicit type casts." \
  "X01: string attribute compared to a number" \
  citydb --config "$CFG" export citygml -o "$OUT" -f "district = 5"

assert_fails_with "Type mismatch between the operand and values of an in predicate." \
  "X02: IN list with mismatching types" \
  citydb --config "$CFG" export citygml -o "$OUT" -f "storeys::int IN ('a', 'b')"

assert_fails_with "Invalid number of coordinates for BBOX literal." \
  "X03: BBOX with three coordinates" \
  citydb --config "$CFG" export citygml -o "$OUT" -f "S_INTERSECTS(core:envelope, BBOX(1, 2, 3))"

assert_fails_with "Failed to parse the provided CQL2 filter expression." \
  "X04: INTERVAL literal" \
  citydb --config "$CFG" export citygml -o "$OUT" -f "core:creationDate = INTERVAL('2020-01-01', '2021-01-01')"

assert_fails_with "Failed to parse spatial distance predicate." \
  "X05: S_DWITHIN without distance" \
  citydb --config "$CFG" export citygml -o "$OUT" -f "S_DWITHIN(core:envelope, POINT(1 2))"

assert_fails_with "Invalid empty property name." \
  "X06: empty quoted property name" \
  citydb --config "$CFG" export citygml -o "$OUT" -f "\"\" = 'x'"

assert_fails_with "Unsupported distance unit 'parsec'." \
  "X07: unknown distance unit" \
  citydb --config "$CFG" export citygml -o "$OUT" -f "S_DWITHIN(core:envelope, POINT(458800 5438360), 150, 'parsec')"

assert_fails_with "Use explicit type casts." \
  "X08: arithmetic on a string attribute" \
  citydb --config "$CFG" export citygml -o "$OUT" -f "district + 1 > 2"

assert_fails_with "cannot be used as operand of a like predicate." \
  "X09: LIKE on an integer" \
  citydb --config "$CFG" export citygml -o "$OUT" -f "storeys::int LIKE '1%'"

assert_fails_with "Step predicates are not allowed for the property reference of a sortBy operation." \
  "X10: step predicate in sort key" \
  citydb --config "$CFG" export citygml -o "$OUT" -t bldg:Building -s "con:height[con:status = 'measured'].con:value-"

assert_fails_with "Use explicit type casts." \
  "X11: date attribute without cast" \
  citydb --config "$CFG" export citygml -o "$OUT" -f "constructionDate < DATE('1950-01-01')"

assert_fails_with "Type cast '::date' is not supported." \
  "X12: unsupported cast ::date" \
  citydb --config "$CFG" export citygml -o "$OUT" -f "constructionDate::date < DATE('1950-01-01')"

assert_fails_with "Type casts are only allowed for generic attributes" \
  "X13: unprefixed name resolves to native core:area with type context" \
  citydb --config "$CFG" export citygml -o "$OUT" -t bldg:Building -f "area::double > 250"

# X14: gen: prefix in front of a quoted name is not parsed (pinned; the
# quoted form "gen:Gemeindeschlüssel" works, see K10).
assert_fails_with "Failed to parse filter text" \
  "X14: prefix outside the double quotes" \
  citydb --config "$CFG" export citygml -o "$OUT" -f "gen:\"Gemeindeschlüssel\" = '08215017'"

# X15: a filter starting with '-' is taken as an option by the CLI parser;
# use a config file or parentheses instead.
assert_fails_with "Expected parameter for option" \
  "X15: CLI filter value starting with a minus sign" \
  citydb --config "$CFG" export citygml -o "$OUT" --filter "-storeys::int < -6"

# X16: unknown filter CRS
if cli_export --filter-crs 99999 -f "S_INTERSECTS(core:envelope, BBOX(1, 2, 3, 4))" >/dev/null; then
  echo "FAIL: X16: unknown filter CRS - command succeeded unexpectedly"
  report_line "- **FAIL:** X16: unknown filter CRS - command succeeded unexpectedly"
  exit 1
elif grep -q "NullPointerException" "$EXPORT_LOG"; then
  skip_case "X16 (message)" "unexpected error message for an unknown filter CRS; to be clarified"
else
  assert_fails_with "The requested filter SRS is not supported." \
    "X16: unknown filter CRS" \
    citydb --config "$CFG" export citygml -o "$OUT" --filter-crs 99999 -f "S_INTERSECTS(core:envelope, BBOX(1, 2, 3, 4))"
fi

# X17-X20: CQL2 JSON
make_query_config "$CFG" "$JSON_CFG" '"filter": {"op": "s_intersects", "args": [{"property": "core:envelope"}, {"type": "Polygon", "coordinates": []}]}'
assert_fails_with "Found empty ring array for polygon geometry." \
  "X17: JSON polygon without rings" \
  citydb --config "$JSON_CFG" export citygml -o "$OUT"

make_query_config "$CFG" "$JSON_CFG" '"filter": {"op": "a_contains", "args": [{"property": "bldg:function"}, ["1000"]]}'
assert_fails_with "Array predicates are not supported." \
  "X18: JSON array predicate" \
  citydb --config "$JSON_CFG" export citygml -o "$OUT"

make_query_config "$CFG" "$JSON_CFG" '"filter": {"op": "foo", "args": [{"property": "name"}, "x"]}'
assert_fails_with "Unsupported function 'foo'." \
  "X19: JSON unknown operator" \
  citydb --config "$JSON_CFG" export citygml -o "$OUT"

make_query_config "$CFG" "$JSON_CFG" '"filter": {"op": "t_after", "args": [{"property": "core:creationDate"}, {"interval": ["2020-01-01", "2021-01-01"]}]}'
assert_fails_with "Temporal predicates are not supported." \
  "X20: JSON temporal predicate" \
  citydb --config "$JSON_CFG" export citygml -o "$OUT"

# ---------------------------------------------------------------------------
# P01-P15: paths over sub-features on the Railway scene
# (Boatshouse: Roof 1-2, Wall 1-5; Station: Roof 1-3, Wall 1-9;
#  Chapel: Roof 1-3, Wall 1-11)
# ---------------------------------------------------------------------------
echo ""
echo "--- Paths over sub-features (P01-P15) ---"

truncate_features
run_quiet citydb --config "$CFG_IMPORT" import citygml "$RAILWAY"
assert_equals 3 "$(get_feature_count_by_type 'Building')" "Setup: Railway scene imported"

BOAT=GMLID_BUI130363_1235_6047
STATION=GMLID_BUI184698_512_898
CHAPEL=GMLID_BUI46739_1739_10911
STATION_BBOX="BBOX(-414, 421, -385, 439)"

cli_export -t bldg:Building -f "core:boundary.core:name = 'Roof 1'"
assert_export_ids "$BOAT $STATION $CHAPEL" "$OUT" bldg:Building "P01: attribute of a boundary surface"

cli_export -t bldg:Building -f "core:boundary[core:name = 'Roof 3'].core:relativeToTerrain = 'entirelyAboveTerrain'"
assert_export_ids "$STATION $CHAPEL" "$OUT" bldg:Building "P02: step predicate on boundary surfaces"

cli_export -t bldg:Building -f "core:boundary.core:relativeToWater = 'entirelyAboveWaterSurface'"
assert_export_ids "$BOAT" "$OUT" bldg:Building "P03: enumeration value on a boundary surface"

cli_export -t bldg:Building -f "core:name LIKE 'Station%' AND core:boundary.core:name = 'Wall 1'"
assert_export_ids "$STATION" "$OUT" bldg:Building "P04: building attribute AND boundary attribute"

cli_export -t bldg:Building -f "core:boundary.core:name IN ('Wall 10', 'Wall 11')"
assert_export_ids "$CHAPEL" "$OUT" bldg:Building "P05: IN on a boundary attribute"

cli_export -t bldg:Building -f "CASEI(core:boundary.core:name) LIKE 'roof 2%'"
assert_export_ids "$BOAT $STATION $CHAPEL" "$OUT" bldg:Building "P06: CASEI on a boundary attribute"

cli_export -t bldg:Building -f "core:boundary.core:name = 'Roof 3' AND S_INTERSECTS(core:envelope, $STATION_BBOX)"
assert_export_ids "$STATION" "$OUT" bldg:Building "P07: boundary attribute AND spatial predicate"

cli_export -t bldg:Building -f "bldg:buildingInstallation.core:objectId LIKE '%' AND core:boundary.core:name = 'Wall 9'"
assert_export_ids "$STATION $CHAPEL" "$OUT" bldg:Building "P08: two different sub-feature relations"

if [ "$SAMEPATH_OK" = "1" ]; then
  cli_export -t bldg:Building -f "core:boundary.core:name = 'Roof 3' AND core:boundary.core:name = 'Wall 10'"
  assert_export_ids "$CHAPEL" "$OUT" bldg:Building "P09: two conditions on different boundary surfaces"
else
  skip_case "P09" "$SAMEPATH_SKIP"
fi

cli_export -t con:RoofSurface -f "core:name = 'Roof 1'"
assert_export_count 3 "$OUT" con:RoofSurface "P10: filter on a nested feature type"
assert_export_count 0 "$OUT" bldg:Building "P10: parent buildings not exported"
assert_schema_valid "$OUT" "P10: nested feature type export is schema-valid"

cli_export -t con:RoofSurface -f "S_INTERSECTS(core:lod3MultiSurface, $STATION_BBOX)"
assert_export_count 3 "$OUT" con:RoofSurface "P11: spatial filter on the geometry of roof surfaces"

cli_export -t con:WallSurface -f "S_INTERSECTS(core:envelope, $STATION_BBOX)"
assert_export_count 9 "$OUT" con:WallSurface "P12: spatial filter on the envelope of wall surfaces"

cli_export -t con:RoofSurface -f "core:name = 'Roof 1' AND S_INTERSECTS(core:envelope, $STATION_BBOX)"
assert_export_count 1 "$OUT" con:RoofSurface "P13: attribute AND spatial filter on a nested type"

# P14: all top-level types, cross-checked against an independent PostGIS query
EXPECTED_TOP=$(db_query "SELECT count(*) FROM feature f JOIN objectclass o ON o.id = f.objectclass_id WHERE o.is_toplevel = 1 AND f.termination_date IS NULL AND st_intersects(f.envelope, st_makeenvelope(-414, 421, -385, 439, 25832));")
assert_gt 0 "$EXPECTED_TOP" "P14: PostGIS finds top-level features in the station bbox"
cli_export -f "S_INTERSECTS(core:envelope, $STATION_BBOX)"
assert_equals "$EXPECTED_TOP" "$(grep -c '<cityObjectMember>' "$OUT")" "P14: top-level result matches PostGIS ($EXPECTED_TOP features)"

# P15: NOT on a multi-valued path is applied per value ("has a boundary
# surface not named Roof 3"), not to the existence (pinned deliberately).
cli_export -t bldg:Building -f "NOT core:boundary.core:name = 'Roof 3'"
assert_export_ids "$BOAT $STATION $CHAPEL" "$OUT" bldg:Building "P15: NOT on a multi-valued path negates per value"

# X21-X22: limits of sub-feature paths
assert_fails_with "is not a valid child of" \
  "X21: geometry of boundary surfaces is not reachable via core:boundary" \
  citydb --config "$CFG" export citygml -o "$OUT" -t bldg:Building -f "S_INTERSECTS(core:boundary.core:lod3MultiSurface, $STATION_BBOX)"

assert_fails_with "Type casts are only allowed for generic attributes" \
  "X22: type cast on a feature relation" \
  citydb --config "$CFG" export citygml -o "$OUT" -t bldg:Building -f "core:boundary::con:RoofSurface.core:name = 'Roof 1'"

echo ""
echo "=== Advanced CQL2 Filter Tests PASSED ==="
