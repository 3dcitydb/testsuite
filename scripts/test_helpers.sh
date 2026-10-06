#!/bin/bash
# Common test helper functions sourced by all test scripts.

export PGPASSWORD=test
# Timestamps in query results are compared in UTC.
export PGTZ=UTC
DB_HOST="${DB_HOST:-db}"
DB_USER="${DB_USER:-citydb}"
DB_NAME="${DB_NAME:-citydb}"
# Connection options for citydb commands that run without a config file.
DB_ARGS=(--db-host="$DB_HOST" --db-name="$DB_NAME" --db-username="$DB_USER" --db-password="$PGPASSWORD")

# ---------------------------------------------------------------------------
# Report functions
# ---------------------------------------------------------------------------
# REPORT_FILE is set by run_all_tests.sh. When empty, all report_* calls
# are silent no-ops, so individual test scripts work unchanged.
REPORT_FILE="${REPORT_FILE:-}"

# Initialise the markdown report file with a header.
report_init() {
  [ -z "$REPORT_FILE" ] && return
  cat > "$REPORT_FILE" << EOF
# 3DCityDB Test Suite Report

**Date:** $(date '+%Y-%m-%d %H:%M:%S')
**citydb-tool:** $(citydb --version 2>/dev/null | head -1 | sed 's/^citydb-tool //')
**3DCityDB:** $(db_query "SELECT version FROM citydb_pkg.citydb_version();" 2>/dev/null) (PostgreSQL $(db_query "SELECT split_part(current_setting('server_version'), ' ', 1);" 2>/dev/null), PostGIS $(db_query "SELECT postgis_lib_version();" 2>/dev/null))
**SRID:** 25832 (UTM Zone 32N)

---

EOF
}

# Write a markdown section heading (## title).
report_section() {
  [ -z "$REPORT_FILE" ] && return
  echo "## $1" >> "$REPORT_FILE"
  echo "" >> "$REPORT_FILE"
}

# Append an arbitrary line of text to the report.
report_line() {
  [ -z "$REPORT_FILE" ] && return
  echo "$1" >> "$REPORT_FILE"
}

# Write the summary table and totals from the RESULTS_FILE.
report_finalize() {
  [ -z "$REPORT_FILE" ] && return
  local results_file="${RESULTS_FILE:-}"
  [ -z "$results_file" ] && return
  [ ! -f "$results_file" ] && return

  {
    echo ""
    echo "---"
    echo ""
    echo "## Summary"
    echo ""
    echo "| # | Test | Result | Duration |"
    echo "|---|------|--------|----------|"

    local idx=0 passed=0 failed=0 skipped=0
    while IFS='|' read -r name result duration; do
      idx=$((idx + 1))
      if [ "$result" = "PASS" ]; then
        echo "| $idx | $name | PASS | ${duration}s |"
        passed=$((passed + 1))
      elif [ "$result" = "SKIP" ]; then
        echo "| $idx | $name | SKIP | - |"
        skipped=$((skipped + 1))
      else
        echo "| $idx | $name | **FAIL** | ${duration}s |"
        failed=$((failed + 1))
      fi
    done < "$results_file"

    echo ""
    echo "**Total: $passed passed, $failed failed, $skipped skipped**"

    if [ -n "${SUITE_START:-}" ]; then
      local total=$(( $(date +%s) - SUITE_START ))
      local mins=$(( total / 60 ))
      local secs=$(( total % 60 ))
      echo "**Total duration: ${mins}m ${secs}s**"
    fi
    echo ""
  } >> "$REPORT_FILE"

  rm -f "$results_file"
}

# ---------------------------------------------------------------------------
# Database helpers
# ---------------------------------------------------------------------------

# Execute a SQL query and return the result on one line, with rows and
# repeated blanks collapsed into single spaces.  Fails when psql fails.
db_query() {
  local query="$1" out
  out=$(psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" -t -c "$query") || return 1
  echo "$out" | tr -s ' \n' '  ' | sed 's/^ //; s/ $//'
}

# Execute a SQL query and print one row per line, columns separated by '|'.
db_rows() {
  psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" -At -F '|' -c "$1"
}

# ---------------------------------------------------------------------------
# Assertion helpers (also write to REPORT_FILE when set)
# ---------------------------------------------------------------------------

# Assert that two values are equal.
assert_equals() {
  local expected="$1"
  local actual="$2"
  local msg="${3:-Assertion failed}"
  if [ "$expected" != "$actual" ]; then
    echo "FAIL: $msg (expected=$expected, actual=$actual)"
    report_line "- **FAIL:** $msg (expected=$expected, actual=$actual)"
    exit 1
  fi
  echo "PASS: $msg (value=$actual)"
  report_line "- PASS: $msg (value=$actual)"
}

# Assert that actual value is greater than a threshold.
assert_gt() {
  local threshold="$1"
  local actual="$2"
  local msg="${3:-Assertion failed}"
  if ! [[ "$actual" =~ ^-?[0-9]+$ ]] || [ "$actual" -le "$threshold" ]; then
    echo "FAIL: $msg (expected > $threshold, actual=$actual)"
    report_line "- **FAIL:** $msg (expected > $threshold, actual=$actual)"
    exit 1
  fi
  echo "PASS: $msg (value=$actual > $threshold)"
  report_line "- PASS: $msg (value=$actual > $threshold)"
}

# Assert that a file exists and optionally meets a minimum size.
assert_file_exists() {
  local fp="$1"
  local min_size="${2:-0}"
  local msg="${3:-File check}"
  if [ ! -f "$fp" ]; then
    echo "FAIL: $msg - file not found: $fp"
    report_line "- **FAIL:** $msg - file not found: $fp"
    exit 1
  fi
  local sz
  sz=$(stat -c %s "$fp")
  if [ "$sz" -lt "$min_size" ]; then
    echo "FAIL: $msg - file too small (${sz} < ${min_size})"
    report_line "- **FAIL:** $msg - file too small (${sz} < ${min_size})"
    exit 1
  fi
  echo "PASS: $msg (file=$fp, size=$sz)"
  report_line "- PASS: $msg (size=$sz bytes)"
}

# Assert that a command fails (non-zero exit code).
assert_fails() {
  local msg="$1"
  shift
  if "$@" 2>/dev/null; then
    echo "FAIL: $msg - command succeeded unexpectedly"
    report_line "- **FAIL:** $msg - command succeeded unexpectedly"
    exit 1
  fi
  echo "PASS: $msg - command failed as expected"
  report_line "- PASS: $msg - command failed as expected"
}

# Assert that a command fails AND its output contains an expected message.
# Usage: assert_fails_with "<pattern>" "<msg>" <cmd> [args...]
assert_fails_with() {
  local pattern="$1"
  local msg="$2"
  shift 2
  local output
  if output=$("$@" 2>&1); then
    echo "FAIL: $msg - command succeeded unexpectedly"
    report_line "- **FAIL:** $msg - command succeeded unexpectedly"
    exit 1
  fi
  if ! echo "$output" | grep -qF -- "$pattern"; then
    echo "FAIL: $msg - expected error message not found: $pattern"
    echo "$output" | tail -5
    report_line "- **FAIL:** $msg - expected error message not found: \`$pattern\`"
    exit 1
  fi
  echo "PASS: $msg - failed with expected message"
  report_line "- PASS: $msg - failed with expected message"
}

# ---------------------------------------------------------------------------
# Export feature counting helpers
# ---------------------------------------------------------------------------

# Count features of a given element in a CityGML file.  The pattern is
# anchored on ' gml:id' so that e.g. <bldg:BuildingPart is not counted as
# a substring match of <bldg:Building.  A missing file yields "no-file", so
# that assertions and probes cannot mistake it for an empty result.
count_gml_features() {
  local file="$1"
  local element="$2"
  if [ ! -f "$file" ]; then
    echo no-file
    return
  fi
  grep -c "<${element} gml:id" "$file" || true
}

# Count CityObjects of a given type in a CityJSON file.
count_cityjson_features() {
  local file="$1"
  local type="$2"
  if [ ! -f "$file" ]; then
    echo no-file
    return
  fi
  grep -o "\"type\":\"${type}\"" "$file" | wc -l
}

# Assert the exact number of features in an export file.  Types is a
# comma-separated list of element names (CityGML, e.g. "bldg:Building") or
# CityObject types (CityJSON, e.g. "Building"); counts are summed up.
# The format is chosen by file extension (*.json -> CityJSON).
# Usage: assert_export_count <expected> <file> <types> <msg>
assert_export_count() {
  local expected="$1"
  local file="$2"
  local types="$3"
  local msg="$4"
  local total=0 t c
  if [ ! -f "$file" ]; then
    assert_equals "$expected" "no-file" "$msg"
    return
  fi
  IFS=',' read -ra _aec_types <<< "$types"
  for t in "${_aec_types[@]}"; do
    case "$file" in
      *.json) c=$(count_cityjson_features "$file" "$t") ;;
      *)      c=$(count_gml_features "$file" "$t") ;;
    esac
    total=$((total + c))
  done
  assert_equals "$expected" "$total" "$msg"
}

# List the gml:ids of the given element types (comma-separated) in a CityGML
# file, sorted and space-separated ("no-file" if the file is missing).
# Usage: export_ids <file> <types>
export_ids() {
  local file="$1"
  local re="${2//,/|}"
  [ -f "$file" ] || { echo no-file; return 0; }
  grep -oE "<(${re}) gml:id=\"[^\"]+\"" "$file" | sed 's/.*gml:id="\([^"]*\)"/\1/' | sort | xargs
}

# Assert the exact set of exported features (order-independent), which is
# stronger than a count check.  Expected ids are space-separated.
# Usage: assert_export_ids "<ids>" <file> <types> <msg>
assert_export_ids() {
  local expected
  expected=$(echo "$1" | xargs -n1 2>/dev/null | sort | xargs)
  assert_equals "$expected" "$(export_ids "$2" "$3")" "$4"
}

# List the gml:ids of the given element types (comma-separated) in export
# order ("no-file" if the file is missing).
# Usage: ordered_ids <file> <types>
ordered_ids() {
  local file="$1"
  local re="${2//,/|}"
  [ -f "$file" ] || { echo no-file; return 0; }
  grep -oE "<(${re}) gml:id=\"[^\"]+\"" "$file" | sed 's/.*gml:id="\([^"]*\)"/\1/' | xargs
}

# Run a CityGML export into a fresh output file and keep the tool output in
# EXPORT_LOG.  Fails when the tool fails or writes no file.
# Usage: export_to <config> <output file> [export options...]
EXPORT_LOG=/tmp/export_last.log
export_to() {
  local cfg="$1" out="$2"
  shift 2
  rm -f "$out"
  citydb --config "$cfg" export citygml -o "$out" "$@" > "$EXPORT_LOG" 2>&1 \
    || { echo "Export failed:"; tail -8 "$EXPORT_LOG"; return 1; }
  [ -f "$out" ] || { echo "Export wrote no file: $out"; return 1; }
}

# Record a skipped case in output and report (the test keeps running).
skip_case() {
  local id="$1"
  local reason="$2"
  echo "SKIP: $id - $reason"
  report_line "- SKIP: $id - $reason"
}

# Run a command with its output captured in a log file.  On failure the log
# tail is shown and a FAIL line is reported, so that an abort under set -e
# can be diagnosed.
# Usage: run_quiet <cmd> [args...]
run_quiet() {
  "$@" > /tmp/run_quiet_last.log 2>&1 && return 0
  echo "FAIL: command failed: $*"
  tail -8 /tmp/run_quiet_last.log
  report_line "- **FAIL:** command failed: \`$*\`"
  return 1
}

# Write a copy of a config file whose exportOptions.query is replaced by the
# given JSON members (e.g. '"filter": {...}').  The source config must
# contain an empty '"exportOptions": {}' block.
# Usage: make_query_config <source config> <target config> <query members>
make_query_config() {
  local query="$3"
  query="${query//\\/\\\\}"
  query="${query//&/\\&}"
  query="${query//|/\\|}"
  sed "s|\"exportOptions\": {}|\"exportOptions\": {\"query\": {${query}}}|" "$1" > "$2"
}

# ---------------------------------------------------------------------------
# Schema validation helpers (schemas are baked into the image, see Dockerfile)
# ---------------------------------------------------------------------------
SCHEMA_DIR="${SCHEMA_DIR:-/opt/schemas}"

# Print the path of a wrapper XSD that imports all modules of a CityGML
# version (1.0, 2.0 or 3.0); created on first use.
citygml_schema() {
  local version="$1"
  local wrapper="/tmp/citygml_${version}_all.xsd"
  if [ ! -f "$wrapper" ]; then
    {
      echo '<?xml version="1.0" encoding="UTF-8"?>'
      echo '<xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema">'
      local xsd ns
      for xsd in "$SCHEMA_DIR/citygml/$version"/*.xsd; do
        # code list metadata is not part of instance documents
        [ "$(basename "$xsd")" = codeListMetaData.xsd ] && continue
        ns=$(grep -m1 -o 'targetNamespace="[^"]*"' "$xsd" | cut -d'"' -f2)
        echo "  <xs:import namespace=\"$ns\" schemaLocation=\"$xsd\"/>"
      done
      echo '</xs:schema>'
    } > "$wrapper"
  fi
  echo "$wrapper"
}

# Validate a CityGML file against the schema of its CityGML version, which
# is detected from the core namespace.  Prints the first errors on failure.
# Usage: validate_citygml <file>
validate_citygml() {
  local file="$1" version
  version=$(grep -m1 -oE 'www\.opengis\.net/citygml/[123]\.0"' "$file" | grep -oE '[123]\.0')
  if [ -z "$version" ]; then
    echo "no CityGML core namespace found in $file"
    return 1
  fi
  xmllint --noout --schema "$(citygml_schema "$version")" "$file" > /tmp/xmllint_last.log 2>&1 \
    || { grep -v -e ' validates$' -e 'parser warning' /tmp/xmllint_last.log | head -5; return 1; }
}

# Validate a CityJSON file against the official CityJSON schema.  CityJSON
# Sequences (JSON Lines: a CityJSON header followed by one CityJSONFeature
# per line, the citydb-tool default) are validated line by line against the
# CityJSON and CityJSONFeature schemas.  Prints the first errors on failure.
# Usage: validate_cityjson <file>
validate_cityjson() {
  python3 - "$SCHEMA_DIR/cityjson" "$1" << 'EOF'
import json, sys
from jsonschema import Draft7Validator

def validator(name):
    with open(f"{sys.argv[1]}/{name}.schema.json", encoding="utf-8") as f:
        return Draft7Validator(json.load(f))

with open(sys.argv[2], encoding="utf-8") as f:
    text = f.read()
try:
    documents = [("", json.loads(text), validator("cityjson"))]
except json.JSONDecodeError:
    lines = [line for line in text.splitlines() if line.strip()]
    feature = validator("cityjsonfeature")
    documents = [(f"line {n}: ", json.loads(line), validator("cityjson") if n == 1 else feature)
                 for n, line in enumerate(lines, 1)]
errors = []
for prefix, document, v in documents:
    for e in sorted(v.iter_errors(document), key=lambda e: list(e.path)):
        errors.append(prefix + "/" + "/".join(str(p) for p in e.path) + ": " + e.message[:200])
print("\n".join(errors[:5]))
sys.exit(1 if errors else 0)
EOF
}

# Assert that an export file is schema-valid; the format is chosen by file
# extension (*.json -> CityJSON, otherwise CityGML).
# Usage: assert_schema_valid <file> <msg>
assert_schema_valid() {
  local file="$1" msg="$2" validator errors
  case "$file" in
    *.json) validator=validate_cityjson ;;
    *)      validator=validate_citygml ;;
  esac
  if ! errors=$("$validator" "$file"); then
    echo "FAIL: $msg - schema validation failed"
    echo "$errors"
    report_line "- **FAIL:** $msg - schema validation failed: \`$(echo "$errors" | head -1)\`"
    exit 1
  fi
  echo "PASS: $msg - schema-valid"
  report_line "- PASS: $msg - schema-valid"
}

# ---------------------------------------------------------------------------
# Feature helpers
# ---------------------------------------------------------------------------

# Get total feature count from the database.
get_feature_count() {
  db_query "SELECT count(*) FROM feature;"
}

# Get feature count filtered by object class name.
get_feature_count_by_type() {
  local type="$1"
  db_query "SELECT count(*) FROM feature f JOIN objectclass o ON f.objectclass_id = o.id WHERE o.classname = '$type';"
}

# Delete all features from the database (CASCADE handles foreign key dependencies).
# address, surface_data and tex_image are listed explicitly: they do not
# reference feature, so CASCADE alone would leave orphaned rows behind.
truncate_features() {
  db_query "TRUNCATE feature, address, surface_data, tex_image CASCADE;"
}

# ---------------------------------------------------------------------------
# Custom dataset helpers
# ---------------------------------------------------------------------------

# Resolve the input CityGML file.  When CITYGML_DATASET is set, validate and
# use it; otherwise fall back to the provided default path.
# Usage: INPUT_FILE=$(resolve_citygml_input "/data/synthetic/minimal_building.gml")
resolve_citygml_input() {
  local default_file="$1"
  local custom="${CITYGML_DATASET:-}"

  if [ -z "$custom" ]; then
    echo "$default_file"
    return 0
  fi

  if [ ! -f "$custom" ]; then
    echo "ERROR: Custom dataset not found: $custom" >&2
    echo "  Place the file under ./data/ and use the container path /data/..." >&2
    exit 1
  fi

  local ext="${custom##*.}"
  ext=$(echo "$ext" | tr '[:upper:]' '[:lower:]')
  if [ "$ext" != "gml" ] && [ "$ext" != "xml" ]; then
    echo "ERROR: Custom dataset must be a CityGML file (.gml or .xml), got: $custom" >&2
    exit 1
  fi

  echo "$custom"
}

# Check if a test should be skipped.  SKIP_TESTS is a comma-separated list
# of skip keys (e.g. "delete,roundtrip,error").
# Usage: if is_skipped "delete"; then ... fi
is_skipped() {
  local key="$1"
  local list="${SKIP_TESTS:-}"
  [ -z "$list" ] && return 1
  echo ",$list," | grep -qi ",$key,"
}
