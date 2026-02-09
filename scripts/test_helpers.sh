#!/bin/bash
# Common test helper functions sourced by all test scripts.

export PGPASSWORD=test
DB_HOST="${DB_HOST:-db}"
DB_USER="${DB_USER:-citydb}"
DB_NAME="${DB_NAME:-citydb}"

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
**Database:** PostgreSQL/PostGIS (3dcitydb/3dcitydb-pg)
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

    local idx=0 passed=0 failed=0
    while IFS='|' read -r name result duration; do
      idx=$((idx + 1))
      if [ "$result" = "PASS" ]; then
        echo "| $idx | $name | PASS | ${duration}s |"
        passed=$((passed + 1))
      else
        echo "| $idx | $name | **FAIL** | ${duration}s |"
        failed=$((failed + 1))
      fi
    done < "$results_file"

    echo ""
    echo "**Total: $passed passed, $failed failed**"

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

# Execute a SQL query and return the trimmed result.
db_query() {
  local query="$1"
  psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" -t -c "$query" | xargs
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
  if [ "$actual" -le "$threshold" ]; then
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
    report_line "- **FAIL:** $msg — file not found: $fp"
    exit 1
  fi
  local sz
  sz=$(stat -c %s "$fp")
  if [ "$sz" -lt "$min_size" ]; then
    echo "FAIL: $msg - file too small (${sz} < ${min_size})"
    report_line "- **FAIL:** $msg — file too small (${sz} < ${min_size})"
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
    report_line "- **FAIL:** $msg — command succeeded unexpectedly"
    exit 1
  fi
  echo "PASS: $msg - command failed as expected"
  report_line "- PASS: $msg — command failed as expected"
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
truncate_features() {
  db_query "TRUNCATE feature CASCADE;"
}
