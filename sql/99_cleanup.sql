-- =============================================================================
-- AGENT COMMERCE - Complete Cleanup Script
-- =============================================================================
-- Drops ALL artifacts created by the Agent Commerce demo.
-- Run with ACCOUNTADMIN role. Order matters: dependents first.
-- =============================================================================

USE ROLE ACCOUNTADMIN;

-- ---------------------------------------------------------------------------
-- 1. SPCS Service (must drop before compute pool)
-- ---------------------------------------------------------------------------
DROP SERVICE IF EXISTS AGENT_COMMERCE.UTIL.AGENT_COMMERCE_BACKEND;

-- ---------------------------------------------------------------------------
-- 2. Compute Pool (must be idle after service drop)
-- ---------------------------------------------------------------------------
ALTER COMPUTE POOL IF EXISTS AGENT_COMMERCE_POOL STOP ALL;
DROP COMPUTE POOL IF EXISTS AGENT_COMMERCE_POOL;

-- ---------------------------------------------------------------------------
-- 3. External Access Integration
-- ---------------------------------------------------------------------------
DROP INTEGRATION IF EXISTS SPCS_BACKEND_ACCESS;

-- ---------------------------------------------------------------------------
-- 4. Database (cascades all schemas, tables, views, UDFs, procedures,
--    stages, cortex search services, semantic views, agents, image repos)
-- ---------------------------------------------------------------------------
DROP DATABASE IF EXISTS AGENT_COMMERCE CASCADE;

-- ---------------------------------------------------------------------------
-- 5. Warehouse
-- ---------------------------------------------------------------------------
DROP WAREHOUSE IF EXISTS AGENT_COMMERCE_WH;

-- ---------------------------------------------------------------------------
-- 6. Role (revoke from SYSADMIN first)
-- ---------------------------------------------------------------------------
REVOKE ROLE AGENT_COMMERCE_ROLE FROM ROLE SYSADMIN;
DROP ROLE IF EXISTS AGENT_COMMERCE_ROLE;
