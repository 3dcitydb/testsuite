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

BUILDING_COUNT="${BUILDING_COUNT:-10000}"
CONFIG_IMPORT="/config/config_citygml_import.json"
CONFIG_EXPORT="/config/config_citygml_export.json"
GENERATED_FILE="/data/synthetic/large_dataset.gml"
EXPORT_FILE="/output/perf_export.gml"

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

# ---------------------------------------------------------------------------
# Phase 1: Generate synthetic dataset
# ---------------------------------------------------------------------------
echo "--- Phase 1: Data Generation ---"
GEN_START=$(date +%s)

/scripts/generate_citygml.sh "$BUILDING_COUNT" "$GENERATED_FILE"

GEN_END=$(date +%s)
GEN_ELAPSED=$((GEN_END - GEN_START))

FILE_SIZE=$(stat -c %s "$GENERATED_FILE" 2>/dev/null || stat -f %z "$GENERATED_FILE")
echo "  Generated $BUILDING_COUNT buildings in $(format_duration $GEN_ELAPSED)"
echo "  File size: $(format_bytes $FILE_SIZE) ($FILE_SIZE bytes)"
echo ""

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

# ---------------------------------------------------------------------------
# Phase 3: Import Validation
# ---------------------------------------------------------------------------
echo "--- Phase 3: Import Validation ---"
TOTAL_FEATURES=$(get_feature_count)
assert_gt 0 "$TOTAL_FEATURES" "Total features imported"

BUILDING_COUNT_DB=$(get_feature_count_by_type "Building")
echo "  Buildings in DB:     $BUILDING_COUNT_DB"

WALL_COUNT=$(get_feature_count_by_type "WallSurface")
echo "  WallSurfaces in DB:  $WALL_COUNT"

ROOF_COUNT=$(get_feature_count_by_type "RoofSurface")
echo "  RoofSurfaces in DB:  $ROOF_COUNT"

echo "  Total features:      $TOTAL_FEATURES"
echo ""

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
EXPORT_SIZE=$(stat -c %s "$EXPORT_FILE" 2>/dev/null || stat -f %z "$EXPORT_FILE")
echo "  Export file size: $(format_bytes $EXPORT_SIZE) ($EXPORT_SIZE bytes)"
echo ""

# ---------------------------------------------------------------------------
# Phase 5: Database Statistics
# ---------------------------------------------------------------------------
echo "--- Phase 5: Database Statistics ---"
echo ""

# Total database size
DB_SIZE=$(db_query "SELECT pg_database_size('$DB_NAME');")
echo "  Total database size: $(format_bytes $DB_SIZE)"
echo ""

# Table sizes (top tables by total size)
echo "  Table Sizes (top 10 by total size):"
echo "  -----------------------------------------------------------"
printf "  %-30s %12s %12s %12s\n" "TABLE" "DATA" "INDEXES" "TOTAL"
echo "  -----------------------------------------------------------"

db_query "
  SELECT
    relname || '|' ||
    pg_relation_size(c.oid) || '|' ||
    pg_indexes_size(c.oid) || '|' ||
    pg_total_relation_size(c.oid)
  FROM pg_class c
  JOIN pg_namespace n ON n.oid = c.relnamespace
  WHERE n.nspname = 'public'
    AND c.relkind = 'r'
  ORDER BY pg_total_relation_size(c.oid) DESC
  LIMIT 10;
" | while IFS='|' read -r tbl data_sz idx_sz total_sz; do
  tbl=$(echo "$tbl" | xargs)
  data_sz=$(echo "$data_sz" | xargs)
  idx_sz=$(echo "$idx_sz" | xargs)
  total_sz=$(echo "$total_sz" | xargs)
  if [ -n "$tbl" ]; then
    printf "  %-30s %12s %12s %12s\n" \
      "$tbl" \
      "$(format_bytes "$data_sz")" \
      "$(format_bytes "$idx_sz")" \
      "$(format_bytes "$total_sz")"
  fi
done

echo ""

# Table activity stats
echo "  Table Activity (pg_stat_user_tables):"
echo "  -----------------------------------------------------------"
printf "  %-30s %10s %10s %12s\n" "TABLE" "SEQ_SCAN" "IDX_SCAN" "LIVE_TUPLES"
echo "  -----------------------------------------------------------"

db_query "
  SELECT
    relname || '|' ||
    COALESCE(seq_scan, 0) || '|' ||
    COALESCE(idx_scan, 0) || '|' ||
    COALESCE(n_live_tup, 0)
  FROM pg_stat_user_tables
  WHERE schemaname = 'public'
  ORDER BY n_live_tup DESC
  LIMIT 10;
" | while IFS='|' read -r tbl seq idx tup; do
  tbl=$(echo "$tbl" | xargs)
  seq=$(echo "$seq" | xargs)
  idx=$(echo "$idx" | xargs)
  tup=$(echo "$tup" | xargs)
  if [ -n "$tbl" ]; then
    printf "  %-30s %10s %10s %12s\n" "$tbl" "$seq" "$idx" "$tup"
  fi
done

echo ""

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

# Clean up generated file to save space
rm -f "$GENERATED_FILE"
echo "  Cleaned up generated file."
