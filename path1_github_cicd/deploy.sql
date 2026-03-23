-- ============================================================================
-- AGENT COMMERCE - Complete Deployment from GitHub (Path 1)
-- ============================================================================
--
-- TWO-STEP DEPLOYMENT:
--   Step 1: Run PART A below (creates infra + image repo)
--   Step 2: Push Docker image using pull_and_push.sh
--   Step 3: Run PART B below (deploys everything else)
--
-- PREREQUISITES:
--   1. ACCOUNTADMIN role
--   2. Docker installed locally (for pull_and_push.sh)
--
-- SOURCE REPOSITORY:
--   https://github.com/sfc-gh-amgupta/agent_commerce_beauty_advisor
--
-- ============================================================================


-- ############################################################################
-- PART A: INFRASTRUCTURE (run this first)
-- ############################################################################

-- ============================================================================
-- A1: ROLE AND PRIVILEGE SETUP
-- ============================================================================

USE ROLE ACCOUNTADMIN;

CREATE ROLE IF NOT EXISTS AGENT_COMMERCE_ROLE
    COMMENT = 'Role for Agent Commerce application - owns all demo objects';

GRANT CREATE DATABASE ON ACCOUNT TO ROLE AGENT_COMMERCE_ROLE;
GRANT CREATE WAREHOUSE ON ACCOUNT TO ROLE AGENT_COMMERCE_ROLE;
GRANT CREATE COMPUTE POOL ON ACCOUNT TO ROLE AGENT_COMMERCE_ROLE;
GRANT BIND SERVICE ENDPOINT ON ACCOUNT TO ROLE AGENT_COMMERCE_ROLE;
GRANT CREATE INTEGRATION ON ACCOUNT TO ROLE AGENT_COMMERCE_ROLE;

DECLARE
    current_user_name VARCHAR;
BEGIN
    current_user_name := CURRENT_USER();
    EXECUTE IMMEDIATE 'GRANT ROLE AGENT_COMMERCE_ROLE TO USER "' || current_user_name || '"';
END;

-- ============================================================================
-- A2: GIT INTEGRATION (requires ACCOUNTADMIN for API Integration)
-- ============================================================================

CREATE OR REPLACE API INTEGRATION github_api_integration
    API_PROVIDER = GIT_HTTPS_API
    API_ALLOWED_PREFIXES = ('https://github.com/sfc-gh-amgupta/')
    ENABLED = TRUE
    COMMENT = 'Integration for Agent Commerce GitHub repository';

GRANT USAGE ON INTEGRATION github_api_integration TO ROLE AGENT_COMMERCE_ROLE;

-- ============================================================================
-- A3: DATABASE, GIT REPO, AND INFRASTRUCTURE
-- ============================================================================

USE ROLE AGENT_COMMERCE_ROLE;

CREATE DATABASE IF NOT EXISTS AGENT_COMMERCE
    COMMENT = 'Agent Commerce Demo - AI-powered shopping assistant';

USE DATABASE AGENT_COMMERCE;
CREATE SCHEMA IF NOT EXISTS UTIL COMMENT = 'Utilities, configs, and shared resources';
USE SCHEMA UTIL;

CREATE OR REPLACE GIT REPOSITORY UTIL.AGENT_COMMERCE_GIT
    API_INTEGRATION = github_api_integration
    ORIGIN = 'https://github.com/sfc-gh-amgupta/agent_commerce_beauty_advisor.git'
    COMMENT = 'Agent Commerce source code and data';

ALTER GIT REPOSITORY UTIL.AGENT_COMMERCE_GIT FETCH;

EXECUTE IMMEDIATE FROM @UTIL.AGENT_COMMERCE_GIT/branches/main/sql/01_setup_infrastructure.sql;

-- ============================================================================
-- PART A COMPLETE - Image repo now exists at:
--   AGENT_COMMERCE.UTIL.AGENT_COMMERCE_REPO
--
-- Verify:
SHOW IMAGE REPOSITORIES IN SCHEMA UTIL;
--
-- ############################################################################
-- >>> STOP HERE <<<
-- ############################################################################
--
-- Now push the Docker image to your Snowflake registry.
-- Open a terminal and run:
--
--   cd path1_github_cicd
--   chmod +x pull_and_push.sh
--   ./pull_and_push.sh
--
-- This pulls the pre-built image from Docker Hub (no auth needed)
-- and pushes it to YOUR Snowflake image registry (~5 min).
--
-- After push completes, verify:
SHOW IMAGES IN IMAGE REPOSITORY UTIL.AGENT_COMMERCE_REPO;
--
-- Then continue with PART B below.
-- ############################################################################


-- ############################################################################
-- PART B: APPLICATION (run after image is pushed)
-- ############################################################################

-- ============================================================================
-- B1: CREATE TABLES
-- ============================================================================

EXECUTE IMMEDIATE FROM @UTIL.AGENT_COMMERCE_GIT/branches/main/sql/02_create_tables.sql;

-- ============================================================================
-- B2: LOAD DATA
-- ============================================================================

CREATE OR REPLACE FILE FORMAT UTIL.CSV_FORMAT
    TYPE = CSV
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    PARSE_HEADER = TRUE
    NULL_IF = ('', 'NULL', 'null')
    EMPTY_FIELD_AS_NULL = TRUE
    ERROR_ON_COLUMN_COUNT_MISMATCH = FALSE;

CREATE STAGE IF NOT EXISTS UTIL.CSV_DATA_STAGE
    COMMENT = 'Internal stage for CSV data files';

COPY FILES INTO @UTIL.CSV_DATA_STAGE/
FROM @UTIL.AGENT_COMMERCE_GIT/branches/main/data/csv/
PATTERN = '.*\.csv';

LIST @UTIL.CSV_DATA_STAGE/;

EXECUTE IMMEDIATE FROM @UTIL.AGENT_COMMERCE_GIT/branches/main/sql/03_load_data.sql;

-- ============================================================================
-- B3: VIEWS, UDFS, PROCEDURES
-- ============================================================================

EXECUTE IMMEDIATE FROM @UTIL.AGENT_COMMERCE_GIT/branches/main/sql/04_create_views.sql;

EXECUTE IMMEDIATE FROM @UTIL.AGENT_COMMERCE_GIT/branches/main/sql/05_create_udfs_procedures.sql;

-- ============================================================================
-- B4: CORTEX SEARCH, SEMANTIC VIEWS, AGENT
-- ============================================================================

EXECUTE IMMEDIATE FROM @UTIL.AGENT_COMMERCE_GIT/branches/main/sql/06_create_cortex_search.sql;

EXECUTE IMMEDIATE FROM @UTIL.AGENT_COMMERCE_GIT/branches/main/sql/07_create_semantic_views.sql;

EXECUTE IMMEDIATE FROM @UTIL.AGENT_COMMERCE_GIT/branches/main/sql/08_create_agent.sql;

-- ============================================================================
-- B5: DEPLOY SPCS BACKEND SERVICE
-- ============================================================================

EXECUTE IMMEDIATE FROM @UTIL.AGENT_COMMERCE_GIT/branches/main/sql/09_deploy_spcs.sql;

SELECT SYSTEM$GET_SERVICE_STATUS('UTIL.AGENT_COMMERCE_BACKEND');

-- ============================================================================
-- B6: VERIFICATION
-- ============================================================================

SELECT 'PRODUCTS' AS domain, COUNT(*) AS row_count FROM PRODUCTS.PRODUCTS
UNION ALL SELECT 'CUSTOMERS', COUNT(*) FROM CUSTOMERS.CUSTOMERS
UNION ALL SELECT 'INVENTORY', COUNT(*) FROM INVENTORY.LOCATIONS
UNION ALL SELECT 'SOCIAL', COUNT(*) FROM SOCIAL.PRODUCT_REVIEWS
UNION ALL SELECT 'CART_OLTP', COUNT(*) FROM CART_OLTP.ORDERS;

SELECT SYSTEM$GET_SERVICE_STATUS('UTIL.AGENT_COMMERCE_BACKEND');

SHOW ENDPOINTS IN SERVICE UTIL.AGENT_COMMERCE_BACKEND;

SHOW CORTEX SEARCH SERVICES IN DATABASE AGENT_COMMERCE;

SHOW SEMANTIC VIEWS IN DATABASE AGENT_COMMERCE;

SHOW AGENTS IN SCHEMA UTIL;

-- ============================================================================
-- DEPLOYMENT COMPLETE!
-- ============================================================================
--
-- COMPONENTS DEPLOYED:
--   - Database: AGENT_COMMERCE (6 schemas)
--   - Tables: 31 (including 7 Hybrid Tables in CART_OLTP)
--   - Views: 6
--   - UDFs: 13 | Procedures: 13
--   - Cortex Search Services: 3
--   - Semantic Views: 5
--   - Cortex Agent: AGENTIC_COMMERCE_ASSISTANT (17 tools)
--   - SPCS Backend: agent-commerce-backend (face/skin analysis API)
--
-- CLEANUP:
--   USE ROLE ACCOUNTADMIN;
--   DROP DATABASE IF EXISTS AGENT_COMMERCE CASCADE;
--   DROP WAREHOUSE IF EXISTS AGENT_COMMERCE_WH;
--   DROP COMPUTE POOL IF EXISTS AGENT_COMMERCE_POOL;
--   DROP INTEGRATION IF EXISTS github_api_integration;
--   DROP ROLE IF EXISTS AGENT_COMMERCE_ROLE;
-- ============================================================================
