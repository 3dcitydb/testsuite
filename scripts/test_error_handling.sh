#!/bin/bash
set -e

source /scripts/test_helpers.sh

echo "=== Error Handling Tests ==="
echo "-------------------------------------------"

# Test 1: Import nonexistent file
echo "--- Test: Import nonexistent file ---"
assert_fails "Import nonexistent file" \
  citydb import citygml \
  --db-host=db --db-name=citydb --db-username=citydb --db-password=test \
  /data/this_file_does_not_exist.gml

# Test 2: Import invalid/malformed XML
echo ""
echo "--- Test: Import invalid XML ---"
assert_fails "Import invalid XML" \
  citydb import citygml \
  --db-host=db --db-name=citydb --db-username=citydb --db-password=test \
  /data/synthetic/invalid_citygml.gml

# Test 3: Import with wrong credentials
echo ""
echo "--- Test: Import with bad credentials ---"
assert_fails "Import with bad credentials" \
  citydb --config /config/config_bad_credentials.json import citygml \
  /data/synthetic/minimal_building.gml

# Test 4: Import with bad host
echo ""
echo "--- Test: Import with bad host ---"
assert_fails "Import with bad host" \
  citydb --config /config/config_bad_host.json import citygml \
  /data/synthetic/minimal_building.gml

echo ""
echo "=== Error Handling Tests PASSED ==="
