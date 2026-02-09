#!/bin/bash
# Master test runner — executes all tests and generates a timestamped
# markdown report in /output/.

source /scripts/test_helpers.sh

# ---------------------------------------------------------------------------
# Report setup
# ---------------------------------------------------------------------------
TIMESTAMP=$(date '+%Y-%m-%d_%H%M%S')
export REPORT_FILE="/output/report_${TIMESTAMP}.md"
export RESULTS_FILE=$(mktemp)
export SUITE_START=$(date +%s)

report_init

FAILED=0

# Run a single test, track its result, and update the report.
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
echo "============================"
echo "  STARTING FULL TEST SUITE  "
echo "============================"

run_test "CityGML Import"          /scripts/test_import.sh
run_test "CityGML Export"          /scripts/test_export.sh
run_test "CityJSON Import"         /scripts/test_import_cityjson.sh
run_test "CityJSON Export"         /scripts/test_export_cityjson.sh
run_test "Filtered Export"         /scripts/test_export_filtered.sh
run_test "Delete / Terminate"      /scripts/test_delete.sh
run_test "Index Management"        /scripts/test_index.sh
run_test "Roundtrip"               /scripts/test_roundtrip.sh
run_test "Duplicate Handling"      /scripts/test_duplicate_handling.sh
run_test "Error Handling"          /scripts/test_error_handling.sh
run_test "Info Command"            /scripts/test_info.sh

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
