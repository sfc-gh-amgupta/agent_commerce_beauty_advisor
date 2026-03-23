-- =============================================================================
-- AGENT COMMERCE - Infrastructure Setup
-- =============================================================================
-- Creates the foundational infrastructure: role, database, schemas, warehouse,
-- compute pool, image repository, stage, and file format.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 1. Role
-- ---------------------------------------------------------------------------
USE ROLE ACCOUNTADMIN;

CREATE ROLE IF NOT EXISTS AGENT_COMMERCE_ROLE;
GRANT ROLE AGENT_COMMERCE_ROLE TO ROLE SYSADMIN;

-- Grant necessary account-level privileges
GRANT CREATE DATABASE ON ACCOUNT TO ROLE AGENT_COMMERCE_ROLE;
GRANT CREATE WAREHOUSE ON ACCOUNT TO ROLE AGENT_COMMERCE_ROLE;
GRANT CREATE COMPUTE POOL ON ACCOUNT TO ROLE AGENT_COMMERCE_ROLE;
GRANT BIND SERVICE ENDPOINT ON ACCOUNT TO ROLE AGENT_COMMERCE_ROLE;

-- ---------------------------------------------------------------------------
-- 2. Database
-- ---------------------------------------------------------------------------
USE ROLE AGENT_COMMERCE_ROLE;

CREATE DATABASE IF NOT EXISTS AGENT_COMMERCE;

-- ---------------------------------------------------------------------------
-- 3. Schemas
-- ---------------------------------------------------------------------------
USE DATABASE AGENT_COMMERCE;

CREATE SCHEMA IF NOT EXISTS PRODUCTS;
CREATE SCHEMA IF NOT EXISTS CUSTOMERS;
CREATE SCHEMA IF NOT EXISTS INVENTORY;
CREATE SCHEMA IF NOT EXISTS SOCIAL;
CREATE SCHEMA IF NOT EXISTS CART_OLTP;
CREATE SCHEMA IF NOT EXISTS UTIL;

-- ---------------------------------------------------------------------------
-- 4. Warehouse
-- ---------------------------------------------------------------------------
CREATE WAREHOUSE IF NOT EXISTS AGENT_COMMERCE_WH
    WAREHOUSE_SIZE = 'X-SMALL'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE;

USE WAREHOUSE AGENT_COMMERCE_WH;

-- ---------------------------------------------------------------------------
-- 5. Compute Pool (for SPCS)
-- ---------------------------------------------------------------------------
CREATE COMPUTE POOL IF NOT EXISTS AGENT_COMMERCE_POOL
    MIN_NODES = 1
    MAX_NODES = 3
    INSTANCE_FAMILY = CPU_X64_XS;

-- ---------------------------------------------------------------------------
-- 6. Image Repository
-- ---------------------------------------------------------------------------
CREATE IMAGE REPOSITORY IF NOT EXISTS AGENT_COMMERCE.UTIL.AGENT_COMMERCE_REPO;

-- ---------------------------------------------------------------------------
-- 7. Internal Stage for CSV Data
-- ---------------------------------------------------------------------------
USE SCHEMA AGENT_COMMERCE.UTIL;

CREATE STAGE IF NOT EXISTS CSV_DATA_STAGE
    COMMENT = 'Internal stage for CSV data files';

-- ---------------------------------------------------------------------------
-- 8. File Format
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FILE FORMAT CSV_FORMAT
    PARSE_HEADER = TRUE
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    NULL_IF = ('', 'NULL', 'null')
    ERROR_ON_COLUMN_COUNT_MISMATCH = FALSE;

-- ---------------------------------------------------------------------------
-- 9. Grant database-level privileges to role
-- ---------------------------------------------------------------------------
USE ROLE ACCOUNTADMIN;

GRANT USAGE ON DATABASE AGENT_COMMERCE TO ROLE AGENT_COMMERCE_ROLE;
GRANT ALL ON DATABASE AGENT_COMMERCE TO ROLE AGENT_COMMERCE_ROLE;
GRANT ALL ON ALL SCHEMAS IN DATABASE AGENT_COMMERCE TO ROLE AGENT_COMMERCE_ROLE;
GRANT USAGE ON WAREHOUSE AGENT_COMMERCE_WH TO ROLE AGENT_COMMERCE_ROLE;

USE ROLE AGENT_COMMERCE_ROLE;
USE DATABASE AGENT_COMMERCE;
USE WAREHOUSE AGENT_COMMERCE_WH;
