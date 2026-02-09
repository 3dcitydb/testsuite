#!/bin/bash
set -e

source /scripts/test_helpers.sh

echo "=== Index Management Tests ==="
echo "-------------------------------------------"

# Test 1: Check index status
echo "--- Test: Index status ---"
echo "Checking current index status..."
citydb index status --db-host=db --db-name=citydb --db-username=citydb --db-password=test
echo "PASS: Index status command succeeded"

# Test 2: Drop indexes
echo ""
echo "--- Test: Drop indexes ---"
echo "Dropping indexes..."
citydb index drop --db-host=db --db-name=citydb --db-username=citydb --db-password=test
echo "PASS: Index drop command succeeded"

# Test 3: Verify indexes are dropped (status check)
echo ""
echo "--- Test: Verify indexes dropped ---"
citydb index status --db-host=db --db-name=citydb --db-username=citydb --db-password=test
echo "PASS: Index status after drop succeeded"

# Test 4: Recreate indexes
echo ""
echo "--- Test: Create indexes ---"
echo "Creating indexes..."
citydb index create --db-host=db --db-name=citydb --db-username=citydb --db-password=test
echo "PASS: Index create command succeeded"

# Test 5: Verify indexes are created (status check)
echo ""
echo "--- Test: Verify indexes created ---"
citydb index status --db-host=db --db-name=citydb --db-username=citydb --db-password=test
echo "PASS: Index status after create succeeded"

echo ""
echo "=== Index Management Tests PASSED ==="
