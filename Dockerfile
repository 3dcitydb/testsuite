# Dockerfile

# Use the official citydb-tool image as our starting point
FROM 3dcitydb/citydb-tool:latest

# Switch to the root user to be able to install packages
USER root

# Update the package list and install the PostgreSQL client (which includes psql)
RUN apt-get update && \
    apt-get install -y --no-install-recommends postgresql-client && \
    rm -rf /var/lib/apt/lists/*