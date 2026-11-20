# 3DCityDB 5.0 and citydb-tool Test Suite

Automated test suite for the [3D City Database](https://www.3dcitydb.org/) 5.0 and the associated [citydb-tool](https://github.com/3dcitydb/citydb-tool) CLI. Tests validate CityGML/CityJSON import, export, delete, index, and round-trip operations against a PostgreSQL/PostGIS database using Docker containers.

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) and [Docker Compose](https://docs.docker.com/compose/install/) (v2+)

## Quick Start

```bash
# Run the full test suite
docker compose up --build --exit-code-from test-all

# Clean up after tests
docker compose down -v
```

A timestamped report is written to `output/report_YYYY-MM-DD_HHMMSS.md` after every full suite run.

## Architecture

The test suite uses a Docker Compose multi-container setup:

| Container | Image | Purpose |
|-----------|-------|---------|
| **db** | `3dcitydb/3dcitydb-pg` | PostgreSQL/PostGIS with 3DCityDB schema (SRID 25832) |
| **test-*** | Custom (based on `3dcitydb/citydb-tool:latest`) | Runs citydb-tool commands + psql for DB validation |

The custom test image adds `postgresql-client` (psql) to the official citydb-tool image for database validation queries. A health check on the DB container gates test execution until PostgreSQL is ready.

### Database Connection

| Parameter | Value |
|-----------|-------|
| Host | `db` (Docker network) |
| User | `citydb` |
| Password | `test` |
| Database | `citydb` |
| Port | 5432 |
| SRID | 25832 (UTM Zone 32N) |

## Test Scripts

All test scripts are in `scripts/` and use `set -e` for fail-fast behavior. Most scripts source `test_helpers.sh` for common assertion and database query functions.

| Script | Profile | Description |
|--------|---------|-------------|
| `run_all_tests.sh` | *(default)* | Master runner that executes all tests sequentially |
| `test_import.sh` | `import` | CityGML import with feature count validation |
| `test_export.sh` | `export` | CityGML export with file size validation |
| `test_import_cityjson.sh` | `import-cityjson` | CityJSON import with feature count validation |
| `test_export_cityjson.sh` | `export-cityjson` | CityJSON export with file existence check |
| `test_export_filtered.sh` | `export-filtered` | Filtered export by feature type and bounding box |
| `test_delete.sh` | `delete` | Physical delete and soft delete (terminate) operations |
| `test_index.sh` | `index` | Index lifecycle: status, drop, create |
| `test_roundtrip.sh` | `roundtrip` | Import -> export -> reimport, compare feature counts |
| `test_duplicate_handling.sh` | `duplicate` | Double import behavior validation |
| `test_error_handling.sh` | `error` | Negative tests: bad file, bad XML, wrong credentials, wrong host |
| `test_info.sh` | `info` | Database info command validation |
| `test_perf.sh` | `perf` | Performance test with large synthetic data (see below) |

### Test Helper Library (`test_helpers.sh`)

Shared functions sourced by all test scripts:

- `db_query()` -- Execute SQL via psql, return trimmed result
- `assert_equals()` -- Equality assertion with descriptive message
- `assert_gt()` -- Greater-than numeric assertion
- `assert_file_exists()` -- File existence + minimum size check
- `assert_fails()` -- Verify a command exits non-zero (negative testing)
- `get_feature_count()` -- Total feature count from DB
- `get_feature_count_by_type()` -- Feature count filtered by objectclass name
- `truncate_features()` -- Clear all features for test isolation
- `resolve_citygml_input()` -- Resolve custom or default CityGML input file
- `is_skipped()` -- Check if a test should be skipped via `SKIP_TESTS`

## Running Tests

### Full Suite

Runs all 11 test scripts in sequence:

```bash
docker compose up --build --exit-code-from test-all
```

`--exit-code-from test-all` makes the command return non-zero if any test fails, suitable for CI/CD pipelines.

### Individual Tests

Run a specific test using its Docker Compose profile:

```bash
# CityGML import
docker compose --profile import up --build --exit-code-from test-import

# CityGML export (requires data in DB from a prior import)
docker compose --profile export up --build --exit-code-from test-export

# CityJSON import
docker compose --profile import-cityjson up --build --exit-code-from test-import-cityjson

# CityJSON export
docker compose --profile export-cityjson up --build --exit-code-from test-export-cityjson

# Filtered export (by feature type, by bounding box)
docker compose --profile export-filtered up --build --exit-code-from test-export-filtered

# Delete and terminate operations
docker compose --profile delete up --build --exit-code-from test-delete

# Index management (status, drop, create)
docker compose --profile index up --build --exit-code-from test-index

# Round-trip consistency (import -> export -> reimport -> compare)
docker compose --profile roundtrip up --build --exit-code-from test-roundtrip

# Duplicate import handling
docker compose --profile duplicate up --build --exit-code-from test-duplicate

# Error handling (bad input, bad credentials, bad host)
docker compose --profile error up --build --exit-code-from test-error

# Database info command
docker compose --profile info up --build --exit-code-from test-info
```

### Skipping Tests

When running the full suite, you can skip individual tests by setting the `SKIP_TESTS` environment variable with a comma-separated list of skip keys:

```bash
SKIP_TESTS=delete,roundtrip,error docker compose up --build --exit-code-from test-all
```

Available skip keys:

| Key | Test |
|-----|------|
| `import` | CityGML Import |
| `export` | CityGML Export |
| `cityjson-import` | CityJSON Import |
| `cityjson-export` | CityJSON Export |
| `filtered-export` | Filtered Export |
| `delete` | Delete / Terminate |
| `index` | Index Management |
| `roundtrip` | Roundtrip |
| `duplicate` | Duplicate Handling |
| `error` | Error Handling |
| `info` | Info Command |

Skipped tests appear as **SKIP** in the report summary.

### Cleanup

Remove all containers, networks, and the database volume:

```bash
docker compose down -v
```

The `-v` flag removes the named volume containing PostgreSQL data, ensuring a clean state for the next run.

## Custom CityGML Dataset

You can run the test suite against your own CityGML data instead of the built-in datasets.

### Setup

1. Place your `.gml` file somewhere under the `data/` directory (e.g., `data/custom/mydata.gml`).
2. Set the `CITYGML_DATASET` environment variable to the **container path** (prefix with `/data/`):

```bash
CITYGML_DATASET=/data/custom/mydata.gml \
  docker compose up --build --exit-code-from test-all
```

### Which tests use your data?

| Uses custom dataset | Always uses built-in data |
|---------------------|---------------------------|
| CityGML Import | CityJSON Import / Export (needs `.city.json`) |
| CityGML Export | Filtered Export (needs building + road) |
| Delete / Terminate | Error Handling (needs invalid XML) |
| Roundtrip | Index Management (DB-only, no data) |
| Duplicate Handling | |
| Info Command | |

### Examples

```bash
# Run all tests with custom data
CITYGML_DATASET=/data/custom/mydata.gml \
  docker compose up --build --exit-code-from test-all

# Run with custom data, skip some tests
CITYGML_DATASET=/data/custom/mydata.gml \
  SKIP_TESTS=delete,duplicate,error \
  docker compose up --build --exit-code-from test-all

# Run only the import test with custom data
CITYGML_DATASET=/data/custom/mydata.gml \
  docker compose --profile import up --build --exit-code-from test-import
```

> **Note:** The database is configured for SRID 25832 (UTM Zone 32N). Datasets using a different CRS may import successfully, but spatial filter tests (bounding box export) may produce unexpected results.

## Performance Test

The performance test generates a large synthetic CityGML dataset, imports and exports it, and reports detailed timing metrics plus database statistics. It runs as a separate profile and is **not** included in the default test suite.

### How it works

1. **Generates** N buildings (each with 4 WallSurfaces + 1 RoofSurface) on a spatial grid
2. **Imports** the generated file into the database, measuring wall-clock time
3. **Validates** feature counts by type (Building, WallSurface, RoofSurface)
4. **Exports** all data back to CityGML, measuring wall-clock time
5. **Collects** database statistics: table sizes, index sizes, total DB size, scan counts
6. **Prints** a formatted summary and writes a report to `output/report_perf_*.md`

### Running

```bash
# Default: 10,000 buildings (~150 MB generated file)
docker compose --profile perf up --build --exit-code-from test-perf

# Custom scale: 50,000 buildings (~750 MB)
BUILDING_COUNT=50000 docker compose --profile perf up --build --exit-code-from test-perf

# Small quick test: 1,000 buildings (~15 MB)
BUILDING_COUNT=1000 docker compose --profile perf up --build --exit-code-from test-perf
```

### Approximate dataset sizes

| Buildings | Generated file | Features in DB |
|-----------|---------------|----------------|
| 1,000 | ~15 MB | ~6,000 |
| 10,000 | ~150 MB | ~60,000 |
| 50,000 | ~750 MB | ~300,000 |
| 100,000 | ~1.5 GB | ~600,000 |

Each building produces 6 features (1 Building + 4 WallSurface + 1 RoofSurface).

### Data generator

The `scripts/generate_citygml.sh` script can also be used standalone to create synthetic CityGML data:

```bash
# Inside the container or any bash environment
./scripts/generate_citygml.sh 5000 output/synthetic_5k.gml
```

Arguments: `BUILDING_COUNT` (default 10000), `OUTPUT_FILE` (default `/data/synthetic/large_dataset.gml`).

## Test Reports

Every full suite run (`test-all`) and every standalone performance test (`test-perf`) generates a timestamped Markdown report in the `output/` directory:

- **Full suite:** `output/report_2026-02-09_143022.md`
- **Performance test:** `output/report_perf_2026-02-09_150512.md`

Reports include:
- Date, database info, and custom dataset details (if any)
- Per-test results (PASS / FAIL / SKIP) with assertion details
- Duration per test
- Summary table with totals
- For performance tests: timing breakdown, feature counts, table sizes, index stats

## Test Data

### Railway Scene (`data/Railway_Scene/`)

A CityGML 3.0 LoD3 dataset containing buildings, roads, and other city objects with texture appearances. Used for import/export and round-trip tests.

### Synthetic Data (`data/synthetic/`)

Minimal test files created specifically for targeted test scenarios:

| File | Format | Description |
|------|--------|-------------|
| `minimal_building.gml` | CityGML 3.0 | 1 Building with BuildingPart, WallSurface, RoofSurface (EPSG:25832) |
| `building_v2.gml` | CityGML 2.0 | Same building in CityGML 2.0 format for version compatibility testing |
| `minimal_building.city.json` | CityJSON 2.0 | 1 Building with Solid geometry |
| `minimal_road.gml` | CityGML 3.0 | 1 Road with TrafficSpace and TrafficArea |
| `invalid_citygml.gml` | Malformed XML | Intentionally broken XML for error handling tests |

## Configuration Files

JSON configuration files for citydb-tool operations are in `config/`:

| File | Purpose |
|------|---------|
| `config_citygml_import.json` | CityGML import with DB connection settings |
| `config_citygml_export.json` | CityGML export settings |
| `config_cityjson_export.json` | CityJSON 2.0 export settings |
| `config_export_buildings.json` | Export with Building feature type filter |
| `config_export_bbox.json` | Export with bounding box filter |
| `config_bad_credentials.json` | Wrong password for error testing |
| `config_bad_host.json` | Nonexistent host for error testing |

## Project Structure

```
testsuite/
  docker-compose.yml       Docker Compose service definitions
  Dockerfile               Custom test image (citydb-tool + psql)
  config/                  JSON configs for citydb-tool operations
    config_citygml_import.json
    config_citygml_export.json
    config_cityjson_export.json
    config_export_buildings.json
    config_export_bbox.json
    config_bad_credentials.json
    config_bad_host.json
  data/
    Railway_Scene/         CityGML 3.0 LoD3 dataset with textures
    synthetic/             Minimal test files for targeted scenarios
  scripts/
    run_all_tests.sh       Master test runner
    test_helpers.sh        Shared assertion and DB query functions
    generate_citygml.sh    Synthetic CityGML data generator
    test_import.sh         CityGML import test
    test_export.sh         CityGML export test
    test_import_cityjson.sh
    test_export_cityjson.sh
    test_export_filtered.sh
    test_delete.sh
    test_index.sh
    test_roundtrip.sh
    test_duplicate_handling.sh
    test_error_handling.sh
    test_info.sh
    test_perf.sh           Performance / stress test
  output/                  Generated export files and reports (gitignored)
```

## CI/CD Integration

The test suite is designed for CI/CD pipelines. The `--exit-code-from` flag ensures the Docker Compose command returns non-zero on test failure:

```yaml
# Example GitHub Actions step
- name: Run integration tests
  run: |
    cd testsuite
    docker compose up --build --exit-code-from test-all
    docker compose down -v
```
