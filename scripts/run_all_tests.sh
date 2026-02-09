#!/bin/bash
# Master test runner — executes all tests and generates a timestamped
# markdown report in /output/.
#
# Environment variables:
#   CITYGML_DATASET  — path to a custom CityGML file (inside the container,
#                      e.g. /data/custom/mydata.gml).  When set, applicable
#                      tests use this file instead of their defaults.
#   SKIP_TESTS       — comma-separated list of tests to skip, e.g.
#                      "delete,roundtrip,error".  See skip keys below.

source /scripts/test_helpers.sh

# ---------------------------------------------------------------------------
# Report setup
# ---------------------------------------------------------------------------
TIMESTAMP=$(date '+%Y-%m-%d_%H%M%S')
export REPORT_FILE="/output/report_${TIMESTAMP}.md"
export RESULTS_FILE=$(mktemp)
export SUITE_START=$(date +%s)

report_init

# ---------------------------------------------------------------------------
# Custom dataset — validate early and log in report
# ---------------------------------------------------------------------------
if [ -n "${CITYGML_DATASET:-}" ]; then
  echo "Custom dataset: $CITYGML_DATASET"

  if [ ! -f "$CITYGML_DATASET" ]; then
    echo "ERROR: Custom dataset not found: $CITYGML_DATASET"
    echo "  Place the file under ./data/ and use the container path /data/..."
    exit 1
  fi

  DS_SIZE=$(stat -c %s "$CITYGML_DATASET" 2>/dev/null || stat -f %z "$CITYGML_DATASET")
  report_line "**Custom Dataset:** \`$CITYGML_DATASET\`"
  report_line "**Dataset Size:** $DS_SIZE bytes"
  report_line ""
else
  echo "Using default test datasets."
fi

if [ -n "${SKIP_TESTS:-}" ]; then
  echo "Skip list: $SKIP_TESTS"
  report_line "**Skipped tests:** $SKIP_TESTS"
  report_line ""
fi

FAILED=0

# ---------------------------------------------------------------------------
# Run a single test, track its result, and update the report.
# ---------------------------------------------------------------------------
run_test() {
  local name="$1"
  local script="$2"

  echo ""
  echo "--- Running $name ---"
  report_section "$name"

  local start end elapsed
  start=$(date +%s)

  if "$script"; then
    end=$(date +%s)
    elapsed=$((end - start))
    echo "${name}|PASS|${elapsed}" >> "$RESULTS_FILE"
    report_line ""
    report_line "> Duration: ${elapsed}s"
    report_line ""
  else
    end=$(date +%s)
    elapsed=$((end - start))
    echo "${name}|FAIL|${elapsed}" >> "$RESULTS_FILE"
    report_line ""
    report_line "> **FAILED** after ${elapsed}s"
    report_line ""
    FAILED=1
  fi
}

# ---------------------------------------------------------------------------
# Run a test unless its skip key appears in SKIP_TESTS.
# ---------------------------------------------------------------------------
maybe_run_test() {
  local name="$1"
  local script="$2"
  local skip_key="$3"

  if is_skipped "$skip_key"; then
    echo ""
    echo "--- SKIPPING $name ($skip_key) ---"
    report_section "$name"
    report_line "> **SKIPPED**"
    report_line ""
    echo "${name}|SKIP|0" >> "$RESULTS_FILE"
    return
  fi

  run_test "$name" "$script"
}

# ---------------------------------------------------------------------------
echo "============================"
echo "  STARTING FULL TEST SUITE  "
echo "============================"

maybe_run_test "CityGML Import"          /scripts/test_import.sh              import
maybe_run_test "CityGML Export"          /scripts/test_export.sh              export
maybe_run_test "CityJSON Import"         /scripts/test_import_cityjson.sh     cityjson-import
maybe_run_test "CityJSON Export"         /scripts/test_export_cityjson.sh     cityjson-export
maybe_run_test "Filtered Export"         /scripts/test_export_filtered.sh     filtered-export
maybe_run_test "Delete / Terminate"      /scripts/test_delete.sh              delete
maybe_run_test "Index Management"        /scripts/test_index.sh               index
maybe_run_test "Roundtrip"               /scripts/test_roundtrip.sh           roundtrip
maybe_run_test "Duplicate Handling"      /scripts/test_duplicate_handling.sh   duplicate
maybe_run_test "Error Handling"          /scripts/test_error_handling.sh       error
maybe_run_test "Info Command"            /scripts/test_info.sh                info

# ---------------------------------------------------------------------------
# Finalize report
# ---------------------------------------------------------------------------
report_finalize

echo ""
if [ "$FAILED" -eq 0 ]; then
  echo "============================"
  echo "  FULL TEST SUITE PASSED!   "
  echo "============================"
else
  echo "============================="
  echo "  SOME TESTS FAILED!         "
  echo "============================="
fi

echo ""
echo "Report saved to: $REPORT_FILE"

exit "$FAILED"
