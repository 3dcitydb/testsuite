#!/bin/bash
# Master test runner with summary report.
# Runs ALL tests (does not stop on first failure) and prints a report at the end.

PASS_COUNT=0
FAIL_COUNT=0
TOTAL_COUNT=0
declare -a TEST_RESULTS=()

# Run a single test script and record the result.
# Usage: run_test "Test Name" /scripts/test_script.sh
run_test() {
  local name="$1"
  local script="$2"
  TOTAL_COUNT=$((TOTAL_COUNT + 1))

  echo ""
  echo "--------------------------------------------"
  echo "  [$TOTAL_COUNT] $name"
  echo "--------------------------------------------"

  local start_time
  start_time=$(date +%s)

  set +e
  "$script"
  local exit_code=$?
  set -e

  local end_time
  end_time=$(date +%s)
  local duration=$((end_time - start_time))

  if [ $exit_code -eq 0 ]; then
    PASS_COUNT=$((PASS_COUNT + 1))
    TEST_RESULTS+=("PASS|${name}|${duration}s")
  else
    FAIL_COUNT=$((FAIL_COUNT + 1))
    TEST_RESULTS+=("FAIL|${name}|${duration}s")
  fi
}

# ============================================================
echo ""
echo "============================================"
echo "       3DCityDB Test Suite"
echo "============================================"
echo "  Started: $(date '+%Y-%m-%d %H:%M:%S')"
echo "============================================"

run_test "CityGML Import"          /scripts/test_import.sh
run_test "CityGML Export"          /scripts/test_export.sh
run_test "CityJSON Import"         /scripts/test_import_cityjson.sh
run_test "CityJSON Export"         /scripts/test_export_cityjson.sh
run_test "Filtered Export"         /scripts/test_export_filtered.sh
run_test "Delete / Terminate"      /scripts/test_delete.sh
run_test "Index Management"        /scripts/test_index.sh
run_test "Roundtrip (Import-Export-Reimport)" /scripts/test_roundtrip.sh
run_test "Duplicate Handling"      /scripts/test_duplicate_handling.sh
run_test "Error Handling"          /scripts/test_error_handling.sh
run_test "Info Command"            /scripts/test_info.sh

# ============================================================
#  TEST REPORT
# ============================================================
echo ""
echo ""
echo "============================================"
echo "            TEST REPORT"
echo "============================================"
echo ""
printf "  %-4s  %-40s  %s\n" "#" "Test" "Duration"
echo "  ---   ----------------------------------------  --------"

i=1
for result in "${TEST_RESULTS[@]}"; do
  IFS='|' read -r status name duration <<< "$result"
  if [ "$status" = "PASS" ]; then
    marker="[PASS]"
  else
    marker="[FAIL]"
  fi
  printf "  %-4s  %s %-34s  %s\n" "$i" "$marker" "$name" "$duration"
  i=$((i + 1))
done

echo ""
echo "============================================"
echo "  Total: $TOTAL_COUNT  |  Passed: $PASS_COUNT  |  Failed: $FAIL_COUNT"
echo "============================================"

if [ $FAIL_COUNT -gt 0 ]; then
  echo ""
  echo "  FAILED TESTS:"
  for result in "${TEST_RESULTS[@]}"; do
    IFS='|' read -r status name duration <<< "$result"
    if [ "$status" = "FAIL" ]; then
      echo "    - $name"
    fi
  done
  echo ""
  echo "  TEST SUITE FAILED"
  echo "============================================"
  exit 1
else
  echo ""
  echo "  ALL TESTS PASSED"
  echo "============================================"
  exit 0
fi
