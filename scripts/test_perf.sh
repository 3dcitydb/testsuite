#!/bin/bash
# Performance test: generate large synthetic CityGML, import, export, and
# report timing metrics plus database statistics.
#
# Configure via environment variable:
#   BUILDING_COUNT=10000  (default)
#
# Run:
#   docker compose --profile perf up --build --exit-code-from test-perf
#   BUILDING_COUNT=50000 docker compose --profile perf up --build --exit-code-from test-perf
set -e

source /scripts/test_helpers.sh

# Create a separate report unless REPORT_FILE is already set.
if [ -z "$REPORT_FILE" ]; then
  TIMESTAMP=$(date '+%Y-%m-%d_%H%M%S')
  export REPORT_FILE="/output/report_perf_${TIMESTAMP}.md"
  report_init
  report_section "Performance Test"
fi

BUILDING_COUNT="${BUILDING_COUNT:-10000}"
CONFIG_IMPORT="/config/config_citygml_import.json"
CONFIG_EXPORT="/config/config_citygml_export.json"
GENERATED_FILE="/tmp/large_dataset.gml"
EXPORT_FILE="/output/perf_export.gml"

# Remove the generated dataset also when a step fails.
trap 'rm -f "$GENERATED_FILE"' EXIT

# ---------------------------------------------------------------------------
# Helper: format seconds into human-readable duration
# ---------------------------------------------------------------------------
format_duration() {
  local secs="$1"
  if [ "$secs" -ge 3600 ]; then
    printf "%dh %dm %ds" $((secs/3600)) $((secs%3600/60)) $((secs%60))
  elif [ "$secs" -ge 60 ]; then
    printf "%dm %ds" $((secs/60)) $((secs%60))
  else
    printf "%ds" "$secs"
  fi
}

# ---------------------------------------------------------------------------
# Helper: format bytes into human-readable size
# ---------------------------------------------------------------------------
format_bytes() {
  local bytes="$1"
  if [ "$bytes" -ge 1073741824 ]; then
    echo "$(( bytes / 1073741824 )) GB"
  elif [ "$bytes" -ge 1048576 ]; then
    echo "$(( bytes / 1048576 )) MB"
  elif [ "$bytes" -ge 1024 ]; then
    echo "$(( bytes / 1024 )) KB"
  else
    echo "${bytes} B"
  fi
}

# ---------------------------------------------------------------------------
echo "============================================"
echo "  PERFORMANCE TEST - SYNTHETIC LARGE DATASET"
echo "============================================"
echo ""
echo "Configuration:"
echo "  Building count:    $BUILDING_COUNT"
echo "  Import config:     $CONFIG_IMPORT"
echo "  Export config:     $CONFIG_EXPORT"
echo ""

report_line "**Configuration:** $BUILDING_COUNT buildings"
report_line ""

# ---------------------------------------------------------------------------
# Phase 1: Generate synthetic dataset
# ---------------------------------------------------------------------------
echo "--- Phase 1: Data Generation ---"
GEN_START=$(date +%s)

/scripts/generate_citygml.sh "$BUILDING_COUNT" "$GENERATED_FILE"

GEN_END=$(date +%s)
GEN_ELAPSED=$((GEN_END - GEN_START))

FILE_SIZE=$(stat -c %s "$GENERATED_FILE")
echo "  Generated $BUILDING_COUNT buildings in $(format_duration $GEN_ELAPSED)"
echo "  File size: $(format_bytes $FILE_SIZE) ($FILE_SIZE bytes)"
echo ""

report_line "### Data Generation"
report_line "- Generated **$BUILDING_COUNT** buildings in **$(format_duration $GEN_ELAPSED)**"
report_line "- File size: **$(format_bytes $FILE_SIZE)** ($FILE_SIZE bytes)"
report_line ""

# ---------------------------------------------------------------------------
# Phase 2: Import
# ---------------------------------------------------------------------------
echo "--- Phase 2: Import ---"
truncate_features
echo "  Database cleared."

IMP_START=$(date +%s)

citydb --config "$CONFIG_IMPORT" import citygml "$GENERATED_FILE"

IMP_END=$(date +%s)
IMP_ELAPSED=$((IMP_END - IMP_START))
echo "  Import completed in $(format_duration $IMP_ELAPSED)"
echo ""

report_line "### Import"
report_line "- Duration: **$(format_duration $IMP_ELAPSED)**"

# ---------------------------------------------------------------------------
# Phase 3: Import Validation
# ---------------------------------------------------------------------------
echo "--- Phase 3: Import Validation ---"
TOTAL_FEATURES=$(get_feature_count)
BUILDING_COUNT_DB=$(get_feature_count_by_type "Building")
WALL_COUNT=$(get_feature_count_by_type "WallSurface")
ROOF_COUNT=$(get_feature_count_by_type "RoofSurface")

# Each generated building has 4 wall surfaces and 1 roof surface.
assert_equals "$BUILDING_COUNT" "$BUILDING_COUNT_DB" "All buildings imported"
assert_equals $((4 * BUILDING_COUNT)) "$WALL_COUNT" "All wall surfaces imported"
assert_equals "$BUILDING_COUNT" "$ROOF_COUNT" "All roof surfaces imported"
echo "  Total features:      $TOTAL_FEATURES"
echo ""

report_line "- Buildings: $BUILDING_COUNT_DB | Walls: $WALL_COUNT | Roofs: $ROOF_COUNT | Total: $TOTAL_FEATURES"
report_line ""

# ---------------------------------------------------------------------------
# Phase 4: Export
# ---------------------------------------------------------------------------
echo "--- Phase 4: Export ---"
rm -f "$EXPORT_FILE"

EXP_START=$(date +%s)

citydb --config "$CONFIG_EXPORT" export citygml -o "$EXPORT_FILE"

EXP_END=$(date +%s)
EXP_ELAPSED=$((EXP_END - EXP_START))
echo "  Export completed in $(format_duration $EXP_ELAPSED)"

assert_file_exists "$EXPORT_FILE" 3072 "Export file has meaningful content"
assert_export_count "$BUILDING_COUNT" "$EXPORT_FILE" bldg:Building "All buildings exported"
EXPORT_SIZE=$(stat -c %s "$EXPORT_FILE")
echo "  Export file size: $(format_bytes $EXPORT_SIZE) ($EXPORT_SIZE bytes)"
echo ""

report_line "### Export"
report_line "- Duration: **$(format_duration $EXP_ELAPSED)**"
report_line "- Export size: **$(format_bytes $EXPORT_SIZE)** ($EXPORT_SIZE bytes)"
report_line ""

# ---------------------------------------------------------------------------
# Phase 5: Database Statistics
# ---------------------------------------------------------------------------
echo "--- Phase 5: Database Statistics ---"
echo ""

# Total database size
DB_SIZE=$(db_query "SELECT pg_database_size('$DB_NAME');")
echo "  Total database size: $(format_bytes $DB_SIZE)"
echo ""

report_line "### Database Statistics"
report_line "- Total DB size: **$(format_bytes $DB_SIZE)**"
report_line ""

# Table sizes (top tables by total size)
echo "  Table Sizes (top 10 by total size):"
echo "  -----------------------------------------------------------"
printf "  %-30s %12s %12s %12s\n" "TABLE" "DATA" "INDEXES" "TOTAL"
echo "  -----------------------------------------------------------"

report_line "| Table | Data | Indexes | Total |"
report_line "|-------|------|---------|-------|"

TABLE_SIZES=$(db_rows "
  SELECT relname, pg_relation_size(c.oid), pg_indexes_size(c.oid), pg_total_relation_size(c.oid)
  FROM pg_class c
  JOIN pg_namespace n ON n.oid = c.relnamespace
  WHERE n.nspname = 'citydb'
    AND c.relkind = 'r'
  ORDER BY pg_total_relation_size(c.oid) DESC
  LIMIT 10;")
while IFS='|' read -r tbl data_sz idx_sz total_sz; do
  if [ -n "$tbl" ]; then
    printf "  %-30s %12s %12s %12s\n" \
      "$tbl" \
      "$(format_bytes "$data_sz")" \
      "$(format_bytes "$idx_sz")" \
      "$(format_bytes "$total_sz")"
    report_line "| $tbl | $(format_bytes "$data_sz") | $(format_bytes "$idx_sz") | $(format_bytes "$total_sz") |"
  fi
done <<< "$TABLE_SIZES"

echo ""
report_line ""

# Table activity stats
echo "  Table Activity (pg_stat_user_tables):"
echo "  -----------------------------------------------------------"
printf "  %-30s %10s %10s %12s\n" "TABLE" "SEQ_SCAN" "IDX_SCAN" "LIVE_TUPLES"
echo "  -----------------------------------------------------------"

report_line "| Table | Seq Scans | Idx Scans | Live Tuples |"
report_line "|-------|-----------|-----------|-------------|"

TABLE_ACTIVITY=$(db_rows "
  SELECT relname, COALESCE(seq_scan, 0), COALESCE(idx_scan, 0), COALESCE(n_live_tup, 0)
  FROM pg_stat_user_tables
  WHERE schemaname = 'citydb'
  ORDER BY n_live_tup DESC
  LIMIT 10;")
while IFS='|' read -r tbl seq idx tup; do
  if [ -n "$tbl" ]; then
    printf "  %-30s %10s %10s %12s\n" "$tbl" "$seq" "$idx" "$tup"
    report_line "| $tbl | $seq | $idx | $tup |"
  fi
done <<< "$TABLE_ACTIVITY"

echo ""
report_line ""

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
TOTAL_ELAPSED=$((GEN_ELAPSED + IMP_ELAPSED + EXP_ELAPSED))

echo "============================================"
echo "  PERFORMANCE TEST COMPLETE"
echo "============================================"
echo "  Buildings:     $BUILDING_COUNT"
echo "  Input size:    $(format_bytes $FILE_SIZE)"
echo "  Export size:   $(format_bytes $EXPORT_SIZE)"
echo "  Features:      $TOTAL_FEATURES"
echo "  ---"
echo "  Generation:    $(format_duration $GEN_ELAPSED)"
echo "  Import:        $(format_duration $IMP_ELAPSED)"
echo "  Export:        $(format_duration $EXP_ELAPSED)"
echo "  Total:         $(format_duration $TOTAL_ELAPSED)"
echo "============================================"

report_line "### Timing Summary"
report_line "- Generation: **$(format_duration $GEN_ELAPSED)**"
report_line "- Import: **$(format_duration $IMP_ELAPSED)**"
report_line "- Export: **$(format_duration $EXP_ELAPSED)**"
report_line "- **Total: $(format_duration $TOTAL_ELAPSED)**"
report_line ""

# Clean up generated file to save space
rm -f "$GENERATED_FILE"
echo "  Cleaned up generated file."

echo ""
echo "Report saved to: $REPORT_FILE"
