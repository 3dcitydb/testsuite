# CityJSON Schemas

Minified CityJSON and CityJSONFeature schemas used to validate CityJSON exports (see `validate_cityjson` in `scripts/test_helpers.sh`). They are stored here so that building the test image does not depend on a download.

| Version | Source |
|---------|--------|
| 2.0.1 | [cityjson/specs, tag 2.0.1](https://github.com/cityjson/specs/tree/2.0.1/schemas), files unchanged |

The schemas are published under [CC0 1.0](https://github.com/cityjson/specs/blob/main/LICENSE).

To add another version, put `cityjson.min.schema.json` and `cityjsonfeature.min.schema.json` into a new `<version>/` directory and build the image with `--build-arg CITYJSON_SCHEMA_VERSION=<version>`.
