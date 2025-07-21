# 3DCityDB 5.0 and citydb-tool Test Suite

This README outlines the testing strategy for the 3DCityDB 5.0 database and the associated citydb-tool. As we embark on
creating a robust testing framework, this document serves as a foundational plan for developing automated tests,
particularly focusing on a Docker-based environment.

## 1. Introduction

The 3DCityDB is a free 3D geodatabase schema and a set of software tools for storing, representing, and managing virtual
3D city models. The citydb-tool is a command-line application designed for importing and exporting 3D city models from
and to the 3DCityDB.

To ensure the quality, reliability, and stability of 3DCityDB 5.0 and the citydb-tool, a comprehensive test suite is
essential. This document proposes an initial strategy for building such a suite, leveraging containerization for
reproducible and isolated testing environments, as supported by the official 3DCityDB documentation.

## 2. Testing Goals

Our primary goals for the test suite are to:

- Verify Core Functionality: Ensure that fundamental operations of 3DCityDB (schema creation, data storage) and
  citydb-tool (import, export, database operations) work as expected.

- Ensure Data Integrity: Confirm that 3D city model data is correctly imported, stored, and exported without loss or
  corruption, maintaining consistency with the 3DCityDB relational schema.

- Automate Testing: Establish an automated process for running tests, facilitating continuous integration and rapid
  feedback on changes.

- Provide Reproducible Environments: Use containerization to guarantee consistent test environments across different
  development machines and CI/CD pipelines, aligning with the Docker-based setup described in the 3DCityDB
  documentation.

## 3. Testing Strategy: Docker-Based Approach

We will implement our test suite using Docker to create isolated and reproducible testing environments. This approach
allows us to define the exact dependencies (database version, citydb-tool version, etc.) and ensures that tests run
consistently regardless of the host system configuration.

### 3.1. Architecture Overview

While a multi-container setup offers strong isolation, a single Docker container can also be used, especially for
simpler initial test setups.

#### Option A: Single Container Approach

In this approach, a single Docker image will contain all necessary components:

- Database System: (e.g., PostgreSQL with PostGIS). We will utilize the official 3DCityDB PostgreSQL/PostGIS Docker
  image.

- citydb-tool: Installed and configured. We will utilize the official citydb-tool Docker image.

- Test Runner: Test scripts (e.g., Python scripts, shell scripts) and their dependencies.

The container will be started, and a script within it will initiate the database, run the tests, and then clean up. When
using this approach, care must be taken to ensure the database service is fully up and ready before the citydb-tool or
test runner attempts to connect.

##### Pros of Single Container:

- Simpler Dockerfile and docker run command.

- Potentially faster startup time as only one container needs to be built and run.

- Less overhead for orchestration (no Docker Compose needed for basic setup).

Cons of Single Container:

- Less isolation between components; if one component has issues, it might affect others more directly.

- Larger Docker image size.

- More complex to manage services within the container (e.g., ensuring PostgreSQL starts before tests run).

#### Option B: Multi-Container Approach (Original Proposal)

This approach uses separate containers for each major component, orchestrated by Docker Compose.

- Database Container: A container running the official 3DCityDB PostgreSQL/PostGIS Docker image.

- citydb-tool Container: A container where the citydb-tool is installed and accessible. This could be a custom image
  built on top of a base OS with Java and the citydb-tool JAR. We will utilize the official citydb-tool Docker image.

- Test Runner Container: A container responsible for orchestrating the tests. This container will contain test scripts (
  e.g., Python scripts using pytest, or shell scripts) that interact with the database and the citydb-tool container.

##### Pros of Multi-Container:

- Better isolation between services.

- Easier to update or swap individual components (e.g., try a different PostgreSQL version).

- More closely mimics production environments where services are often separated.

Cons of Multi-Container:

- Requires Docker Compose for orchestration.

- Potentially longer startup times due to multiple containers.

### 3.2. Workflow

The general workflow for running tests within this Docker environment will be:

1. Environment Setup: Docker (or Docker Compose for multi-container) will be used to bring up the necessary container(
   s) (database, citydb-tool, test runner).

2. Database Preparation: The test runner (or an entrypoint script within the single container) will connect to the
   database instance and execute SQL scripts to create a fresh 3DCityDB database and schema for each test run.

3. Test Execution: The test runner will execute predefined test scenarios, which involve:

- Invoking citydb-tool commands (e.g., import, export) against the database.

- Performing database queries to verify the state of the data.

- Comparing exported data with expected outputs (in later stages).

4. Environment Teardown: After tests are completed, all containers and their associated data will be removed to ensure a
   clean state for subsequent runs.

## 4. Initial Test Scenarios

To start, we will focus on a foundational set of tests that cover the most critical end-to-end functionalities. These
tests will serve as a baseline and can be expanded upon in the future.

### 4.1. Scenario 1: Database Lifecycle Test

This scenario verifies the ability to successfully create and destroy the 3DCityDB database and its schema.

- Objective: Confirm that the database setup and teardown process works without errors.

- Steps:

    1. Create Database: The test runner connects to the PostgreSQL instance and executes SQL commands to create a new
       database.

    2. Create Schema: The test runner then executes the 3DCityDB schema creation scripts against the newly created database.

    3. Verify Schema: Perform a simple database query to ensure core tables of the 3DCityDB schema exist.

    4. Delete Database: The test runner executes SQL commands to drop the entire database.

- Expected Outcome: All steps complete successfully without any errors reported by the database or the citydb-tool.

### 4.2. Scenario 2: Data Import Test

- This scenario verifies the successful import of a 3D city model dataset using the citydb-tool.

- Objective: Ensure the citydb-tool can import a valid CityGML/CityJSON file into the 3DCityDB.

- Prerequisites: A fresh 3DCityDB database and schema (as set up in Scenario 1).

- Steps:

    1. Import Data: The test runner invokes the citydb-tool import command, pointing to a sample CityGML/CityJSON file
       and the configured database connection.

    2. Verify Import Completion: Check the exit code of the citydb-tool command and parse its output for success messages.

    3. (Future Enhancement) Verify Data Count: Query specific tables in the 3DCityDB (e.g., cityobject, building) to
       count the number of imported features and compare it against the expected count from the source file.

- Expected Outcome: The citydb-tool reports a successful import, and no errors are logged.

### 3. Scenario 3: Data Export Test

This scenario verifies the successful export of 3D city model data from the 3DCityDB using the citydb-tool.

- Objective: Ensure the citydb-tool can export data from the 3DCityDB into a CityGML/CityJSON file.

- Prerequisites: A 3DCityDB database containing previously imported data (e.g., from Scenario 2).

- Steps:

    1. Export Data: The test runner invokes the citydb-tool export command, specifying an output file path and the
       database connection.

    2. Example command: citydb-tool -e export -f /output/exported.gml -db test_citydb ...

    3. Verify Export Completion: Check the exit code of the citydb-tool command and parse its output for success
       messages.

    4. (Future Enhancement) Verify Exported File: Check the existence and non-zero size of the exported file. Later,
       more advanced validation could involve parsing the exported file and comparing its content (e.g., feature count,
       specific attributes) with the original imported data.

- Expected Outcome: The citydb-tool reports a successful export, and a valid output file is created.

## 5. Data for Testing

For the initial set of tests, we will use small, representative 3D city model datasets.

- Sample CityGML/CityJSON Files:

    - Start with a very simple CityGML/CityJson file containing a single building or a few basic city objects. This minimizes
      complexity and speeds up test execution.

    - As the test suite grows, we will introduce more complex datasets, including:

        - Files with various geometry types (LoD0-LoD4).
        - Files with large numbers of features to test performance.
        - Datasets representing different CityGML versions to test compatibility as highlighted in the 3DCityDB
          documentation.

    - Data Location: These sample files will be stored within the test suite's repository, accessible to the citydb-tool
container during test runs (e.g., mounted as a Docker volume).

## 6. Future Considerations

As the test suite matures, we plan to expand its capabilities to include:

- Comprehensive Data Validation: Implement robust checks to compare imported data with original sources and exported data
with expected outputs (e.g., using schema validation, geometric checks, attribute comparisons).

- Performance Testing: Measure the time taken for import/export operations with large datasets to identify performance
bottlenecks.

- Negative Testing: Develop tests that feed invalid input to the citydb-tool or database to verify proper error handling
and graceful failure.

- Database Version Compatibility: Test against different versions of supported databases (e.g., PostgreSQL 12, 13, 14, 15,
16).

- Integration with CI/CD: Integrate the Docker-based test suite into our continuous integration and continuous deployment
pipelines to automatically run tests on every code commit.

- Unit and Integration Tests: Beyond end-to-end tests, develop more granular unit tests for specific components of the
citydb-tool and integration tests for interactions between modules.

This README provides a roadmap for establishing a robust testing foundation for 3DCityDB 5.0 and the citydb-tool. By
starting with essential scenarios in a controlled Docker environment, we can systematically build a comprehensive and
reliable test suite.