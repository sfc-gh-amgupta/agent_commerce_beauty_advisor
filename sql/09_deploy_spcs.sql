-- =============================================================================
-- AGENT COMMERCE - Deploy SPCS Service
-- =============================================================================
-- Creates the Snowpark Container Services backend for face analysis and
-- embedding extraction.
-- =============================================================================

USE ROLE AGENT_COMMERCE_ROLE;
USE DATABASE AGENT_COMMERCE;
USE WAREHOUSE AGENT_COMMERCE_WH;
USE SCHEMA UTIL;

CREATE SERVICE IF NOT EXISTS UTIL.AGENT_COMMERCE_BACKEND
    IN COMPUTE POOL AGENT_COMMERCE_POOL
    FROM SPECIFICATION $$
    spec:
      containers:
        - name: backend
          image: /AGENT_COMMERCE/UTIL/AGENT_COMMERCE_REPO/agent-commerce-backend:latest
          resources:
            requests:
              cpu: 1
              memory: 4Gi
            limits:
              cpu: 2
              memory: 8Gi
          readinessProbe:
            port: 8000
            path: /health
      endpoints:
        - name: api
          port: 8000
          public: true
    $$
    MIN_INSTANCES = 1
    MAX_INSTANCES = 3
    QUERY_WAREHOUSE = AGENT_COMMERCE_WH
    EXTERNAL_ACCESS_INTEGRATIONS = (SPCS_BACKEND_ACCESS);

-- Verify service status
SHOW SERVICES IN SCHEMA UTIL;
SELECT SYSTEM$GET_SERVICE_STATUS('UTIL.AGENT_COMMERCE_BACKEND');
