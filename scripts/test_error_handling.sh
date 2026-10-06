#!/bin/bash
set -e

source /scripts/test_helpers.sh

echo "=== Error Handling Tests ==="
echo "-------------------------------------------"

assert_fails_with "NoSuchFileException: /data/this_file_does_not_exist.gml" \
  "Import nonexistent file" \
  citydb import citygml "${DB_ARGS[@]}" /data/this_file_does_not_exist.gml

assert_fails_with "Failed to read global objects." \
  "Import invalid XML" \
  citydb import citygml "${DB_ARGS[@]}" /data/synthetic/invalid_citygml.gml

assert_fails_with "password authentication failed" \
  "Import with bad credentials" \
  citydb --config /config/config_bad_credentials.json import citygml /data/synthetic/minimal_building.gml

assert_fails_with "UnknownHostException: nonexistent_host" \
  "Import with bad host" \
  citydb --config /config/config_bad_host.json import citygml /data/synthetic/minimal_building.gml

echo ""
echo "=== Error Handling Tests PASSED ==="
