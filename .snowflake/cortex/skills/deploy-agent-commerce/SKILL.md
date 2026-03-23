---
name: deploy-agent-commerce
description: "Deploy the Agent Commerce beauty advisor demo to a Snowflake account. Creates database, tables, Cortex Agent, Cortex Search, Semantic Views, and SPCS backend service. Use when: deploy agent commerce, setup beauty advisor demo, install agent commerce, deploy commerce demo. Triggers: agent commerce, beauty advisor, deploy demo, commerce demo."
---

# Deploy Agent Commerce Demo

Fully automated deployment of the Agent Commerce beauty advisor demo using Cortex Code tools.

## Prerequisites

- ACCOUNTADMIN role on the target Snowflake account
- Docker installed locally (for SPCS image push)
- Account in an SPCS-supported region

## Workflow

### Step 1: Confirm Prerequisites

**Ask** user to confirm:
1. Do you have ACCOUNTADMIN access on this account?
2. Is this account in an SPCS-supported region?

**Check** Docker is available:
```bash
docker --version
```

**If Docker is NOT installed:**

On macOS, check for Homebrew and install:
```bash
brew --version && brew install --cask docker
```

If Homebrew is not available:
```bash
curl -fsSL https://get.docker.com | sh
```

After install, remind user to **launch Docker Desktop** and wait for the daemon to start. Verify with:
```bash
docker info
```

**If Docker daemon is not running** (common on macOS after install):
```bash
open -a Docker
```
Wait 15-30 seconds, then re-check with `docker info`.

### Step 2: Create Role and Privileges

Execute each SQL statement via `snowflake_sql_execute`:

```sql
USE ROLE ACCOUNTADMIN;
```

```sql
CREATE ROLE IF NOT EXISTS AGENT_COMMERCE_ROLE
    COMMENT = 'Role for Agent Commerce application - owns all demo objects';
```

```sql
GRANT CREATE DATABASE ON ACCOUNT TO ROLE AGENT_COMMERCE_ROLE;
```

```sql
GRANT CREATE WAREHOUSE ON ACCOUNT TO ROLE AGENT_COMMERCE_ROLE;
```

```sql
GRANT CREATE COMPUTE POOL ON ACCOUNT TO ROLE AGENT_COMMERCE_ROLE;
```

```sql
GRANT BIND SERVICE ENDPOINT ON ACCOUNT TO ROLE AGENT_COMMERCE_ROLE;
```

```sql
GRANT CREATE INTEGRATION ON ACCOUNT TO ROLE AGENT_COMMERCE_ROLE;
```

Grant role to current user:
```sql
DECLARE
    current_user_name VARCHAR;
BEGIN
    current_user_name := CURRENT_USER();
    EXECUTE IMMEDIATE 'GRANT ROLE AGENT_COMMERCE_ROLE TO USER "' || current_user_name || '"';
END;
```

### Step 3: Create Git Integration

Still as ACCOUNTADMIN:
```sql
CREATE OR REPLACE API INTEGRATION github_api_integration
    API_PROVIDER = GIT_HTTPS_API
    API_ALLOWED_PREFIXES = ('https://github.com/sfc-gh-amgupta/')
    ENABLED = TRUE
    COMMENT = 'Integration for Agent Commerce GitHub repository';
```

```sql
GRANT USAGE ON INTEGRATION github_api_integration TO ROLE AGENT_COMMERCE_ROLE;
```

### Step 4: Create Database and Clone Git Repo

Switch role and create database:
```sql
USE ROLE AGENT_COMMERCE_ROLE;
```

```sql
CREATE DATABASE IF NOT EXISTS AGENT_COMMERCE
    COMMENT = 'Agent Commerce Demo - AI-powered shopping assistant';
```

```sql
USE DATABASE AGENT_COMMERCE;
```

```sql
CREATE SCHEMA IF NOT EXISTS UTIL COMMENT = 'Utilities, configs, and shared resources';
```

```sql
USE SCHEMA UTIL;
```

```sql
CREATE OR REPLACE GIT REPOSITORY UTIL.AGENT_COMMERCE_GIT
    API_INTEGRATION = github_api_integration
    ORIGIN = 'https://github.com/sfc-gh-amgupta/agent_commerce_beauty_advisor.git'
    COMMENT = 'Agent Commerce source code and data';
```

```sql
ALTER GIT REPOSITORY UTIL.AGENT_COMMERCE_GIT FETCH;
```

### Step 5: Run Infrastructure Setup

```sql
EXECUTE IMMEDIATE FROM @UTIL.AGENT_COMMERCE_GIT/branches/main/sql/01_setup_infrastructure.sql;
```

Verify image repo was created:
```sql
SHOW IMAGE REPOSITORIES IN SCHEMA UTIL;
```

### Step 6: Push Docker Image

This is the critical step. Use `bash` to clone the repo and run the push script:

```bash
git clone https://github.com/sfc-gh-amgupta/agent_commerce_beauty_advisor.git /tmp/agent_commerce_deploy
```

```bash
chmod +x /tmp/agent_commerce_deploy/path1_github_cicd/pull_and_push.sh && /tmp/agent_commerce_deploy/path1_github_cicd/pull_and_push.sh
```

This takes ~5 minutes. It pulls from Docker Hub and pushes to the user's Snowflake registry.

**If pull_and_push.sh fails** because it can't detect the Snowflake account, the user may need to set environment variables. Check the script and help the user configure `SNOWFLAKE_ACCOUNT`, `SNOWFLAKE_USER`, and `SNOWFLAKE_PASSWORD` if needed.

After push completes, verify:
```sql
SHOW IMAGES IN IMAGE REPOSITORY UTIL.AGENT_COMMERCE_REPO;
```

### Step 7: Create Tables and Load Data

```sql
EXECUTE IMMEDIATE FROM @UTIL.AGENT_COMMERCE_GIT/branches/main/sql/02_create_tables.sql;
```

Create file format and stage, then copy CSV data:
```sql
CREATE OR REPLACE FILE FORMAT UTIL.CSV_FORMAT
    TYPE = CSV
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    PARSE_HEADER = TRUE
    NULL_IF = ('', 'NULL', 'null')
    EMPTY_FIELD_AS_NULL = TRUE
    ERROR_ON_COLUMN_COUNT_MISMATCH = FALSE;
```

```sql
CREATE STAGE IF NOT EXISTS UTIL.CSV_DATA_STAGE
    COMMENT = 'Internal stage for CSV data files';
```

```sql
COPY FILES INTO @UTIL.CSV_DATA_STAGE/
FROM @UTIL.AGENT_COMMERCE_GIT/branches/main/data/csv/
PATTERN = '.*\.csv';
```

```sql
EXECUTE IMMEDIATE FROM @UTIL.AGENT_COMMERCE_GIT/branches/main/sql/03_load_data.sql;
```

### Step 8: Create Views, UDFs, Procedures

```sql
EXECUTE IMMEDIATE FROM @UTIL.AGENT_COMMERCE_GIT/branches/main/sql/04_create_views.sql;
```

```sql
EXECUTE IMMEDIATE FROM @UTIL.AGENT_COMMERCE_GIT/branches/main/sql/05_create_udfs_procedures.sql;
```

### Step 9: Create Cortex Services and Agent

```sql
EXECUTE IMMEDIATE FROM @UTIL.AGENT_COMMERCE_GIT/branches/main/sql/06_create_cortex_search.sql;
```

```sql
EXECUTE IMMEDIATE FROM @UTIL.AGENT_COMMERCE_GIT/branches/main/sql/07_create_semantic_views.sql;
```

```sql
EXECUTE IMMEDIATE FROM @UTIL.AGENT_COMMERCE_GIT/branches/main/sql/08_create_agent.sql;
```

### Step 10: Deploy SPCS Backend

```sql
EXECUTE IMMEDIATE FROM @UTIL.AGENT_COMMERCE_GIT/branches/main/sql/09_deploy_spcs.sql;
```

Wait for the service to start (can take 2-5 minutes):
```sql
SELECT SYSTEM$GET_SERVICE_STATUS('UTIL.AGENT_COMMERCE_BACKEND');
```

If status shows PENDING, wait 30 seconds and retry. Repeat up to 10 times.

### Step 11: Verify Deployment

Run all verification queries:

```sql
SELECT 'PRODUCTS' AS domain, COUNT(*) AS row_count FROM PRODUCTS.PRODUCTS
UNION ALL SELECT 'CUSTOMERS', COUNT(*) FROM CUSTOMERS.CUSTOMERS
UNION ALL SELECT 'INVENTORY', COUNT(*) FROM INVENTORY.LOCATIONS
UNION ALL SELECT 'SOCIAL', COUNT(*) FROM SOCIAL.PRODUCT_REVIEWS
UNION ALL SELECT 'CART_OLTP', COUNT(*) FROM CART_OLTP.ORDERS;
```

```sql
SHOW ENDPOINTS IN SERVICE UTIL.AGENT_COMMERCE_BACKEND;
```

```sql
SHOW CORTEX SEARCH SERVICES IN DATABASE AGENT_COMMERCE;
```

```sql
SHOW SEMANTIC VIEWS IN DATABASE AGENT_COMMERCE;
```

```sql
SHOW AGENTS IN SCHEMA UTIL;
```

**Present summary to user:**
- Database: AGENT_COMMERCE (6 schemas)
- Tables: 31 (including 7 Hybrid Tables)
- Views: 6
- UDFs: 13 | Procedures: 13
- Cortex Search Services: 3
- Semantic Views: 5
- Cortex Agent: AGENTIC_COMMERCE_ASSISTANT (17 tools)
- SPCS Backend endpoint URL (from SHOW ENDPOINTS output)

Clean up temp files:
```bash
rm -rf /tmp/agent_commerce_deploy
```

## Stopping Points

- After Step 1: if prerequisites not met (no Docker, no ACCOUNTADMIN)
- After Step 5: before Docker push (confirm image repo exists)
- After Step 6: if Docker push fails (help troubleshoot)

## Troubleshooting

**Docker not found**: Install via `brew install --cask docker` (macOS) or `curl -fsSL https://get.docker.com | sh` (Linux)

**Docker daemon not running**: `open -a Docker` (macOS), `sudo systemctl start docker` (Linux), wait 15-30 seconds

**pull_and_push.sh fails with auth error**: User needs to run `docker login <registry-url>` first. The registry URL can be found from `SHOW IMAGE REPOSITORIES` output.

**SPCS service stuck in PENDING**: Check compute pool status with `DESCRIBE COMPUTE POOL AGENT_COMMERCE_POOL`. If IDLE, the service should start within 5 minutes. If SUSPENDED, it needs to resume first.

**EXECUTE IMMEDIATE fails**: Ensure Git repo was fetched (`ALTER GIT REPOSITORY UTIL.AGENT_COMMERCE_GIT FETCH`) and retry.

## Cleanup

If user wants to remove everything:
```sql
USE ROLE ACCOUNTADMIN;
DROP DATABASE IF EXISTS AGENT_COMMERCE CASCADE;
DROP WAREHOUSE IF EXISTS AGENT_COMMERCE_WH;
DROP COMPUTE POOL IF EXISTS AGENT_COMMERCE_POOL;
DROP INTEGRATION IF EXISTS github_api_integration;
DROP ROLE IF EXISTS AGENT_COMMERCE_ROLE;
```

## Output

Fully deployed Agent Commerce demo with:
- Working Cortex Agent with 17 tools
- SPCS backend service with public endpoint
- 3 Cortex Search services
- 5 Semantic Views
- 31 tables loaded with seed data
