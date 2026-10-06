# 3DCityDB v5 and citydb-tool Test Suite

Automated test suite for the [3D City Database](https://www.3dcitydb.org/) v5 and the associated [citydb-tool](https://github.com/3dcitydb/citydb-tool) CLI. Tests validate CityGML/CityJSON import, export, delete, index, and round-trip operations against a PostgreSQL/PostGIS database using Docker containers.

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) and [Docker Compose](https://docs.docker.com/compose/install/) (v2+)

## Quick Start

```bash
# Run the full test suite
docker compose up --build --exit-code-from test-all test-all

# Clean up after tests
docker compose down -v
```

A timestamped report is written to `output/` after every full suite run (see [Test Reports](#test-reports)).

## Architecture

The test suite uses a Docker Compose multi-container setup:

| Container | Image | Purpose |
|-----------|-------|---------|
| **db** | `3dcitydb/3dcitydb-pg:17-3.5-5.1.4` | PostgreSQL/PostGIS with 3DCityDB schema (SRID 25832) |
| **test-*** | Custom (based on `3dcitydb/citydb-tool:1.4.0`) | Runs citydb-tool commands + psql for DB validation |

The custom test image adds `postgresql-client` (psql), `libxml2-utils` (xmllint), `python3-jsonschema` and the schemas for export validation to the official citydb-tool image. The tests run as root inside the container, so files in `output/` are owned by root on Linux hosts. A health check on the DB container gates test execution until PostgreSQL is ready.

### Image Versions

Both images are pinned so that test results (including the skipped cases) are reproducible. To test another release, override the versions via environment variables; `--build` is required when changing the tool version:

```bash
CITYDB_TOOL_VERSION=1.3.2 CITYDB_PG_VERSION=17-3.5-5.1.0 docker compose up --build --exit-code-from test-all test-all
```

The versions actually used are written to the header of every test report.

### Schema Validation

Exports are validated against the official schemas, which are baked into the test image:

- CityGML 1.0/2.0/3.0 and GML: the XSDs bundled with citygml4j, validated offline with `xmllint`.
- CityJSON: the CityJSON and CityJSONFeature schemas, validated with `python3-jsonschema`. CityJSON Sequences are checked line by line. The schema version is set by the build arg `CITYJSON_SCHEMA_VERSION`; building the image downloads it from `3d.bk.tudelft.nl`.

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

All test scripts are in `scripts/`, use `set -e` for fail-fast behavior and source `test_helpers.sh` for common assertion and database query functions. Each script documents its cases in the file header.

| Script | Profile | Description |
|--------|---------|-------------|
| `run_all_tests.sh` | *(default)* | Master runner that executes all tests sequentially |
| `test_import.sh` | `import` | CityGML import with feature count validation |
| `test_export.sh` | `export` | CityGML export of the imported data, feature count and schema validation |
| `test_import_options.sh` | `import-options` | Import modes, filters, metadata and further import options; input sources |
| `test_import_cityjson.sh` | `import-cityjson` | CityJSON import |
| `test_export_cityjson.sh` | `export-cityjson` | CityJSON export with schema validation |
| `test_export_cityjson_options.sh` | `cityjson-options` | CityJSON versions, output formats and further export options |
| `test_export_filtered.sh` | `export-filtered` | Export filtered by feature type and bounding box |
| `test_export_cql2.sh` | `cql2` | CQL2 filters: operators, spatial predicates, attributes, negative cases |
| `test_export_cql2_advanced.sh` | `cql2-advanced` | Advanced CQL2: expressions, typed attributes, CQL2 JSON, sub-feature paths |
| `test_export_cql2_spatial.sh` | `cql2-spatial` | Spatial CQL2: envelope vs geometry, distances, filter CRS, tiling |
| `test_export_options.sh` | `export-options` | CityGML versions, CRS, tiling, LoD, appearances and further export options |
| `test_export_types.sh` | `export-types` | Feature type export: nested types, multiple type names, silent mode |
| `test_delete.sh` | `delete` | Delete and terminate |
| `test_delete_options.sh` | `delete-options` | Preview, termination metadata, limits, validity, address cleanup |
| `test_index.sh` | `index` | Index status, drop and create |
| `test_roundtrip.sh` | `roundtrip` | Import, export and re-import with a feature count comparison |
| `test_roundtrip_content.sh` | `roundtrip-content` | Content fingerprints across CityGML 3.0/2.0 and CityJSON round trips |
| `test_duplicate_handling.sh` | `duplicate` | Second import of the same data |
| `test_error_handling.sh` | `error` | Missing file, malformed XML, wrong credentials, wrong host |
| `test_info.sh` | `info` | Info command: text and JSON report, compact mode, feature scope |
| `test_citydb_pkg.sh` | `pkg` | `citydb_pkg` SQL functions, including a schema SRID change |
| `test_perf.sh` | `perf` | Performance test with large synthetic data (see below) |

### Test Helper Library (`test_helpers.sh`)

- `db_query()`: execute SQL via psql and return the result on one line; `db_rows()`: one row per line
- `assert_equals()`, `assert_gt()`: equality and greater-than assertions
- `assert_file_exists()`: file existence and minimum size check
- `assert_fails()`, `assert_fails_with()`: verify that a command fails (and prints an expected error message)
- `count_gml_features()`, `count_cityjson_features()`: count features of a type in a CityGML or CityJSON file
- `assert_export_count()`: assert the exact number of features in an export file
- `export_ids()`, `ordered_ids()`, `assert_export_ids()`: list or assert the exported gml:ids
- `export_to()`: run a CityGML export into a fresh output file
- `assert_schema_valid()`: validate an export against the CityGML or CityJSON schema
- `skip_case()`: report a skipped case (e.g. an unexpected result that is still to be clarified) and continue
- `run_quiet()`: run a command with its output in a log file; show the log tail on failure
- `make_query_config()`: write a config copy with a given export query (CQL2 JSON filters)
- `get_feature_count()`, `get_feature_count_by_type()`: feature counts from the database
- `truncate_features()`: clear all features for test isolation
- `resolve_citygml_input()`: resolve the custom or default CityGML input file
- `is_skipped()`: check whether a test is listed in `SKIP_TESTS`

## Running Tests

### Full Suite

Runs all 21 test scripts in sequence (all except the performance test):

```bash
docker compose up --build --exit-code-from test-all test-all
```

`--exit-code-from test-all` makes the command return non-zero if any test fails, suitable for CI/CD pipelines.

### Individual Tests

Run a specific test using its Docker Compose profile. Always name the service as well: `test-all` has no profile, so without the service name it starts alongside the selected test and changes the same database concurrently.

```bash
# CityGML import
docker compose --profile import up --build --exit-code-from test-import test-import

# CityGML export (requires data in the DB from a prior import)
docker compose --profile export up --build --exit-code-from test-export test-export

# CityJSON import and export
docker compose --profile import-cityjson up --build --exit-code-from test-import-cityjson test-import-cityjson
docker compose --profile export-cityjson up --build --exit-code-from test-export-cityjson test-export-cityjson

# Filtered export (by feature type, by bounding box)
docker compose --profile export-filtered up --build --exit-code-from test-export-filtered test-export-filtered

# CQL2 filter tests, advanced CQL2 queries and spatial CQL2 filters
docker compose --profile cql2 up --build --exit-code-from test-cql2 test-cql2
docker compose --profile cql2-advanced up --build --exit-code-from test-cql2-advanced test-cql2-advanced
docker compose --profile cql2-spatial up --build --exit-code-from test-cql2-spatial test-cql2-spatial

# CityJSON export options
docker compose --profile cityjson-options up --build --exit-code-from test-cityjson-options test-cityjson-options

# Import, export and delete options; content round trips
docker compose --profile import-options up --build --exit-code-from test-import-options test-import-options
docker compose --profile export-options up --build --exit-code-from test-export-options test-export-options
docker compose --profile delete-options up --build --exit-code-from test-delete-options test-delete-options
docker compose --profile roundtrip-content up --build --exit-code-from test-roundtrip-content test-roundtrip-content

# Feature type export (nested types, multiple --type-name, silent mode)
docker compose --profile export-types up --build --exit-code-from test-export-types test-export-types

# Delete and terminate
docker compose --profile delete up --build --exit-code-from test-delete test-delete

# Index management (status, drop, create)
docker compose --profile index up --build --exit-code-from test-index test-index

# Round trip (import, export, re-import, compare)
docker compose --profile roundtrip up --build --exit-code-from test-roundtrip test-roundtrip

# Duplicate import handling
docker compose --profile duplicate up --build --exit-code-from test-duplicate test-duplicate

# Error handling (bad input, bad credentials, bad host)
docker compose --profile error up --build --exit-code-from test-error test-error

# Database info command
docker compose --profile info up --build --exit-code-from test-info test-info

# citydb_pkg SQL functions (changes the schema SRID temporarily and restores it)
docker compose --profile pkg up --build --exit-code-from test-pkg test-pkg
```

### Skipping Tests

When running the full suite, you can skip individual tests by setting the `SKIP_TESTS` environment variable to a comma-separated list of skip keys. The skip key of a test is its profile name (see [Test Scripts](#test-scripts)):

```bash
SKIP_TESTS=delete,roundtrip,error docker compose up --build --exit-code-from test-all test-all
```

Skipped tests appear as **SKIP** in the report summary.

### Cleanup

Remove all containers, networks, and the database volume:

```bash
docker compose down -v
```

The `-v` flag removes the named volume containing PostgreSQL data, ensuring a clean state for the next run.

## Custom CityGML Dataset

You can run part of the test suite against your own CityGML data instead of the built-in datasets.

### Setup

1. Place your `.gml` file somewhere under the `data/` directory (e.g., `data/custom/mydata.gml`).
2. Set the `CITYGML_DATASET` environment variable to the **container path** (prefix with `/data/`):

```bash
CITYGML_DATASET=/data/custom/mydata.gml \
  docker compose up --build --exit-code-from test-all test-all
```

### Which tests use your data?

These tests import the custom dataset instead of their default data: CityGML Import (and therefore CityGML Export, which exports the imported data), Delete / Terminate, Round Trip, Duplicate Handling and Info Command. All other tests always use the built-in datasets, because their assertions depend on the exact content.

### Examples

```bash
# Run with custom data, skip some tests
CITYGML_DATASET=/data/custom/mydata.gml \
  SKIP_TESTS=delete,duplicate,error \
  docker compose up --build --exit-code-from test-all test-all

# Run only the import test with custom data
CITYGML_DATASET=/data/custom/mydata.gml \
  docker compose --profile import up --build --exit-code-from test-import test-import
```

> **Note:** The database is configured for SRID 25832 (UTM Zone 32N). Datasets using a different CRS may import successfully, but spatial results may differ.

## Performance Test

The performance test generates a large synthetic CityGML dataset, imports and exports it, and reports timing metrics plus database statistics. It runs as a separate profile and is **not** included in the default test suite.

The test generates N buildings (each with 4 wall surfaces and 1 roof surface) on a spatial grid, imports them, checks the feature counts per type, exports all data back to CityGML and collects table sizes, index sizes and scan counts. The generated file is written to `/tmp` inside the container and removed afterwards.

### Running

```bash
# Default: 10,000 buildings (~150 MB generated file)
docker compose --profile perf up --build --exit-code-from test-perf test-perf

# Custom scale: 50,000 buildings (~750 MB)
BUILDING_COUNT=50000 docker compose --profile perf up --build --exit-code-from test-perf test-perf

# Small quick test: 1,000 buildings (~15 MB)
BUILDING_COUNT=1000 docker compose --profile perf up --build --exit-code-from test-perf test-perf
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

Arguments: `BUILDING_COUNT` (default 10000), `OUTPUT_FILE` (default `/tmp/large_dataset.gml`).

## Test Reports

Every full suite run (`test-all`) and every standalone performance test (`test-perf`) generates a timestamped Markdown report in the `output/` directory, e.g. `output/report_2026-02-09_143022.md` and `output/report_perf_2026-02-09_150512.md`.

Reports include:
- Date, citydb-tool, 3DCityDB, PostgreSQL and PostGIS versions, and custom dataset details (if any)
- Per-test results (PASS / FAIL / SKIP) with assertion details
- Duration per test
- Summary table with totals
- For performance tests: timing breakdown, feature counts, table sizes, index stats

## Test Data

### Railway Scene (`data/Railway_Scene/`)

A CityGML 2.0 LoD3 dataset containing buildings, roads, and other city objects with texture appearances. Used for import/export, round-trip, feature type and appearance tests.

### Synthetic Data (`data/synthetic/`)

Small test files created for targeted test scenarios:

| File | Format | Description |
|------|--------|-------------|
| `cql2_features.gml` | CityGML 3.0 | 8 buildings + 2 roads with a deterministic attribute matrix for CQL2 and option tests (see file header) |
| `cql2_spatial.gml` | CityGML 3.0 | 6 buildings + 1 road whose envelopes and geometries differ, for spatial CQL2 tests (see file header) |
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
| `config_export_bbox.json` | Export with a bounding box filter (CQL2) |
| `config_export_cql2_base.json` | DB connection only; the query is given on the command line |
| `config_export_cql2_text.json` | Export with a CQL2 text filter in the config |
| `config_export_cql2_json.json` | Export with a CQL2 JSON filter in the config |
| `config_export_cql2_complex.json` | Export with a nested CQL2 JSON filter in the config |
| `config_bad_credentials.json` | Wrong password for error testing |
| `config_bad_host.json` | Nonexistent host for error testing |

## Project Structure

```
testsuite/
  docker-compose.yml       Docker Compose service definitions
  Dockerfile               Custom test image (citydb-tool + psql + schemas)
  config/                  JSON configs for citydb-tool operations
  data/
    Railway_Scene/         CityGML 2.0 LoD3 dataset with textures
    synthetic/             Small test files for targeted scenarios
  scripts/
    run_all_tests.sh       Master test runner
    test_helpers.sh        Shared assertion and DB query functions
    generate_citygml.sh    Synthetic CityGML data generator
    test_*.sh              Test scripts (see Test Scripts)
  output/                  Generated export files and reports (gitignored)
```

## CI/CD Integration

The GitHub Actions workflow `.github/workflows/testsuite.yml` runs the full suite with the pinned image versions on pushes to `main` and on pull requests. A nightly run uses the `latest` images instead, as an early warning when a new citydb-tool or 3dcitydb-pg release changes results.

Each run publishes the summary table of the report on the run page and uploads the complete `output/` directory (report and exports) as an artifact. A manual run (`workflow_dispatch`) accepts other image versions and skip keys, e.g. to check a new citydb-tool release before changing the pinned version.

The `--exit-code-from` flag ensures the Docker Compose command returns non-zero on test failure, so the suite also fits into other CI systems:

```bash
docker compose up --build --exit-code-from test-all test-all
docker compose down -v
```
