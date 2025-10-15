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
echo "============================"
echo "  FULL TEST SUITE PASSED!   "
echo "============================"