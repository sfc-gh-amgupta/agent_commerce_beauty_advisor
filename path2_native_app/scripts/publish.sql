-- ============================================================================
-- AGENT COMMERCE - Publish Native App Package
-- ============================================================================
-- Run this script as the PROVIDER to create the Application Package,
-- upload all files, and register a version.
--
-- PREREQUISITES:
--   1. Docker image already in: AGENT_COMMERCE.UTIL.AGENT_COMMERCE_REPO
--   2. CSV data files in: path2_native_app/app/data/ (local)
--   3. All app files in: path2_native_app/app/ (local)
--
-- ============================================================================

USE ROLE ACCOUNTADMIN;

GRANT CREATE APPLICATION PACKAGE ON ACCOUNT TO ROLE AGENT_COMMERCE_ROLE;

USE ROLE AGENT_COMMERCE_ROLE;
USE DATABASE AGENT_COMMERCE;
USE WAREHOUSE AGENT_COMMERCE_WH;

-- ============================================================================
-- STEP 1: Create a stage for app package files
-- ============================================================================

CREATE SCHEMA IF NOT EXISTS AGENT_COMMERCE.NATIVE_APP;

CREATE STAGE IF NOT EXISTS AGENT_COMMERCE.NATIVE_APP.APP_STAGE
    COMMENT = 'Stage for Native App package files';

-- ============================================================================
-- STEP 2: Upload app files to stage
-- ============================================================================
-- Run these PUT commands from SnowSQL or Snowflake CLI.
-- Adjust the local path to match your checkout location.
--
-- From the repo root:
--
-- PUT file://path2_native_app/app/manifest.yml @AGENT_COMMERCE.NATIVE_APP.APP_STAGE/ AUTO_COMPRESS=FALSE OVERWRITE=TRUE;
-- PUT file://path2_native_app/app/setup_script.sql @AGENT_COMMERCE.NATIVE_APP.APP_STAGE/ AUTO_COMPRESS=FALSE OVERWRITE=TRUE;
-- PUT file://path2_native_app/app/readme.md @AGENT_COMMERCE.NATIVE_APP.APP_STAGE/ AUTO_COMPRESS=FALSE OVERWRITE=TRUE;
-- PUT file://path2_native_app/app/containers/service_spec.yaml @AGENT_COMMERCE.NATIVE_APP.APP_STAGE/containers/ AUTO_COMPRESS=FALSE OVERWRITE=TRUE;
-- PUT file://data/csv/*.csv @AGENT_COMMERCE.NATIVE_APP.APP_STAGE/data/ AUTO_COMPRESS=FALSE OVERWRITE=TRUE;

-- Verify uploads
LIST @AGENT_COMMERCE.NATIVE_APP.APP_STAGE/;

-- ============================================================================
-- STEP 3: Create Application Package
-- ============================================================================

CREATE APPLICATION PACKAGE IF NOT EXISTS AGENT_COMMERCE_PKG
    COMMENT = 'Agent Commerce - AI-powered beauty shopping assistant with SPCS backend';

-- ============================================================================
-- STEP 4: Register Version
-- ============================================================================

ALTER APPLICATION PACKAGE AGENT_COMMERCE_PKG
    ADD VERSION v1
    USING '@AGENT_COMMERCE.NATIVE_APP.APP_STAGE';

ALTER APPLICATION PACKAGE AGENT_COMMERCE_PKG
    SET DEFAULT RELEASE DIRECTIVE
    VERSION = v1
    PATCH = 0;

-- ============================================================================
-- STEP 5: (Optional) Test locally as consumer
-- ============================================================================

-- CREATE APPLICATION AGENT_COMMERCE_APP
--     FROM APPLICATION PACKAGE AGENT_COMMERCE_PKG
--     USING VERSION v1;
--
-- GRANT CREATE COMPUTE POOL ON ACCOUNT TO APPLICATION AGENT_COMMERCE_APP;
-- GRANT BIND SERVICE ENDPOINT ON ACCOUNT TO APPLICATION AGENT_COMMERCE_APP;
-- GRANT CREATE WAREHOUSE ON ACCOUNT TO APPLICATION AGENT_COMMERCE_APP;
--
-- -- Check status:
-- SHOW SERVICES IN APPLICATION AGENT_COMMERCE_APP;
-- SHOW ENDPOINTS IN SERVICE AGENT_COMMERCE_APP.APP_SCHEMA.AGENT_COMMERCE_BACKEND;

-- ============================================================================
-- STEP 6: (Optional) Grant install to specific role or create listing
-- ============================================================================

-- For private sharing within account:
-- GRANT INSTALL ON APPLICATION PACKAGE AGENT_COMMERCE_PKG TO ROLE <consumer_role>;

-- For Marketplace/Private Listing:
-- Use Snowsight > Provider Studio > Create Listing
-- Attach AGENT_COMMERCE_PKG as the application package

-- ============================================================================
-- CLEANUP (if needed)
-- ============================================================================
-- DROP APPLICATION IF EXISTS AGENT_COMMERCE_APP;
-- DROP APPLICATION PACKAGE IF EXISTS AGENT_COMMERCE_PKG;
-- DROP SCHEMA IF EXISTS AGENT_COMMERCE.NATIVE_APP;
