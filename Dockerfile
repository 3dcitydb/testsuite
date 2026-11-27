# citydb-tool version under test (default: edge, the current development
# state); override with the build arg CITYDB_TOOL_VERSION (docker-compose
# passes it through from the environment).
ARG CITYDB_TOOL_VERSION=edge
FROM 3dcitydb/citydb-tool:${CITYDB_TOOL_VERSION}

# Switch to the root user to be able to install packages
USER root

# Install the PostgreSQL client (psql) for database validation queries and
# xmllint and python3-jsonschema for schema validation of exports.  unzip is
# only needed to extract the CityGML 1.0/2.0/3.0 and GML schemas bundled with
# citygml4j (offline, with relative imports) and is removed afterwards.
RUN apt-get update && \
    apt-get install -y --no-install-recommends postgresql-client libxml2-utils unzip python3-jsonschema && \
    mkdir -p /opt/schemas /tmp/cg && \
    unzip -q /opt/citydb-tool/lib/citygml4j-xml-*.jar 'org/citygml4j/schemas/*' -d /tmp/cg && \
    mv /tmp/cg/org/citygml4j/schemas/* /opt/schemas/ && \
    rm -rf /tmp/cg && \
    apt-get purge -y --auto-remove unzip && \
    rm -rf /var/lib/apt/lists/*

# Official CityJSON and CityJSONFeature schemas used to validate CityJSON
# exports.  They are stored in schemas/cityjson/<version>/ (see the README
# there), so the build does not depend on a download.
ARG CITYJSON_SCHEMA_VERSION=2.0.1
COPY schemas/cityjson/${CITYJSON_SCHEMA_VERSION}/cityjson.min.schema.json /opt/schemas/cityjson/cityjson.schema.json
COPY schemas/cityjson/${CITYJSON_SCHEMA_VERSION}/cityjsonfeature.min.schema.json /opt/schemas/cityjson/cityjsonfeature.schema.json
