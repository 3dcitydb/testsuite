#!/bin/bash
# This script acts as a master test runner.
set -e

echo "============================"
echo "  STARTING FULL TEST SUITE  "
echo "============================"

echo ""
echo "--- Running Import Test ---"
/scripts/test_import.sh

echo ""
echo "--- Running Export Test ---"
/scripts/test_export.sh

echo ""
echo "--- Running CityJSON Import Test ---"
/scripts/test_import_cityjson.sh

echo ""
echo "--- Running CityJSON Export Test ---"
/scripts/test_export_cityjson.sh

echo ""
echo "--- Running Filtered Export Test ---"
/scripts/test_export_filtered.sh

echo ""
echo "--- Running Delete/Terminate Test ---"
/scripts/test_delete.sh

echo ""
echo "--- Running Index Management Test ---"
/scripts/test_index.sh

echo ""
echo "--- Running Roundtrip Test ---"
/scripts/test_roundtrip.sh

echo ""
echo "--- Running Duplicate Handling Test ---"
/scripts/test_duplicate_handling.sh

echo ""
echo "--- Running Error Handling Test ---"
/scripts/test_error_handling.sh

echo ""
echo "--- Running Info Command Test ---"
/scripts/test_info.sh

echo ""
echo "============================"
echo "  FULL TEST SUITE PASSED!   "
echo "============================"