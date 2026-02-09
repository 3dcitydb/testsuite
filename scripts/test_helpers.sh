#!/bin/bash
# Common test helper functions sourced by all test scripts.

export PGPASSWORD=test
DB_HOST="${DB_HOST:-db}"
DB_USER="${DB_USER:-citydb}"
DB_NAME="${DB_NAME:-citydb}"

# Execute a SQL query and return the trimmed result.
db_query() {
  local query="$1"
  psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" -t -c "$query" | xargs
}

# Assert that two values are equal.
assert_equals() {
  local expected="$1"
  local actual="$2"
  local msg="${3:-Assertion failed}"
  if [ "$expected" != "$actual" ]; then
    echo "FAIL: $msg (expected=$expected, actual=$actual)"
    exit 1
  fi
  echo "PASS: $msg (value=$actual)"
}

# Assert that actual value is greater than a threshold.
assert_gt() {
  local threshold="$1"
  local actual="$2"
  local msg="${3:-Assertion failed}"
  if [ "$actual" -le "$threshold" ]; then
    echo "FAIL: $msg (expected > $threshold, actual=$actual)"
    exit 1
  fi
  echo "PASS: $msg (value=$actual > $threshold)"
}

# Assert that a file exists and optionally meets a minimum size.
assert_file_exists() {
  local fp="$1"
  local min_size="${2:-0}"
  local msg="${3:-File check}"
  if [ ! -f "$fp" ]; then
    echo "FAIL: $msg - file not found: $fp"
    exit 1
  fi
  local sz
  sz=$(stat -c %s "$fp")
  if [ "$sz" -lt "$min_size" ]; then
    echo "FAIL: $msg - file too small (${sz} < ${min_size})"
    exit 1
  fi
  echo "PASS: $msg (file=$fp, size=$sz)"
}

# Assert that a command fails (non-zero exit code).
assert_fails() {
  local msg="$1"
  shift
  if "$@" 2>/dev/null; then
    echo "FAIL: $msg - command succeeded unexpectedly"
    exit 1
  fi
  echo "PASS: $msg - command failed as expected"
}

# Get total feature count from the database.
get_feature_count() {
  db_query "SELECT count(*) FROM feature;"
}

# Get feature count filtered by object class name.
get_feature_count_by_type() {
  local type="$1"
  db_query "SELECT count(*) FROM feature f JOIN objectclass o ON f.objectclass_id = o.id WHERE o.classname = '$type';"
}

# Delete all features from the database.
truncate_features() {
  db_query "DELETE FROM feature;"
}
