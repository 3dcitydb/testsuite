# Pinned citydb-tool version; override with the build arg CITYDB_TOOL_VERSION
# (docker-compose passes it through from the environment).
ARG CITYDB_TOOL_VERSION=1.4.0
FROM 3dcitydb/citydb-tool:${CITYDB_TOOL_VERSION}

# Version of the official CityJSON schema used to validate CityJSON exports
ARG CITYJSON_SCHEMA_VERSION=2.0.1

# Switch to the root user to be able to install packages
USER root

# Install the PostgreSQL client (psql) for database validation queries and
# xmllint and python3-jsonschema for schema validation of exports.  unzip
# and curl (the citydb-tool image does not include curl) are only needed for
# the schema setup and are removed afterwards: the CityGML 1.0/2.0/3.0 and
# GML schemas bundled with citygml4j (offline, with relative imports) and
# the official CityJSON and CityJSONFeature schemas.
RUN apt-get update && \
    apt-get install -y --no-install-recommends postgresql-client libxml2-utils unzip curl ca-certificates python3-jsonschema && \
    mkdir -p /opt/schemas/cityjson /tmp/cg && \
    unzip -q /opt/citydb-tool/lib/citygml4j-xml-*.jar 'org/citygml4j/schemas/*' -d /tmp/cg && \
    mv /tmp/cg/org/citygml4j/schemas/* /opt/schemas/ && \
    rm -rf /tmp/cg && \
    for s in cityjson cityjsonfeature; do \
      curl -fsSL -o /opt/schemas/cityjson/$s.schema.json \
        "https://3d.bk.tudelft.nl/schemas/cityjson/${CITYJSON_SCHEMA_VERSION}/$s.min.schema.json"; \
    done && \
    apt-get purge -y --auto-remove unzip curl && \
    rm -rf /var/lib/apt/lists/*
