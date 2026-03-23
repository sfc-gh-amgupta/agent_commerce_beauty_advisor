# Path 1: GitHub CI/CD Deployment

Deploy the full Agent Commerce demo into your Snowflake account using Snowsight + one terminal command.

## Overview

| Step | Where | What |
|------|-------|------|
| 1 | Snowsight | Run **Part A** of `deploy.sql` (creates infra + image repo) |
| 2 | Terminal | Run `pull_and_push.sh` (pushes Docker image to your registry) |
| 3 | Snowsight | Run **Part B** of `deploy.sql` (deploys everything else) |

**Requirements:** Docker installed locally (for image push only). No fork needed.

## Step 1: Run Part A in Snowsight

1. Open Snowsight
2. Create a new SQL Worksheet
3. Paste the contents of `deploy.sql`
4. Run everything from the top down to the `>>> STOP HERE <<<` marker

This creates:
- `AGENT_COMMERCE_ROLE` with required privileges
- API Integration for GitHub
- `AGENT_COMMERCE` database with `UTIL` schema
- Git Repository clone of the public repo
- All infrastructure (schemas, warehouse, compute pool, image repo, stages)

## Step 2: Push Docker Image

Open a terminal and run:

```bash
cd path1_github_cicd
chmod +x pull_and_push.sh
./pull_and_push.sh
```

This pulls `amitgupta392/agent-commerce-backend:latest` from Docker Hub (public, no auth) and pushes it to your Snowflake image registry. Takes ~5 minutes.

### Alternative: GitHub Actions

If you prefer not to install Docker locally, you can fork this repo and use the GitHub Action:

1. Fork this repository
2. Add secrets: `SNOWFLAKE_ACCOUNT`, `SNOWFLAKE_USER`, `SNOWFLAKE_PASSWORD`
3. Run **Actions > Deploy Docker Image to Snowflake Registry**

## Step 3: Run Part B in Snowsight

Back in the same Snowsight worksheet, continue running from `PART B` onward. This:
- Creates all 31 tables (including 7 Hybrid Tables)
- Loads 24 CSV data files from the Git repo
- Creates views, UDFs, and stored procedures
- Creates Cortex Search services, Semantic Views, and the Cortex Agent
- Deploys the SPCS backend service

## Verification

After deployment, check:

```sql
SELECT SYSTEM$GET_SERVICE_STATUS('AGENT_COMMERCE.UTIL.AGENT_COMMERCE_BACKEND');
SHOW AGENTS IN SCHEMA AGENT_COMMERCE.UTIL;
SELECT COUNT(*) FROM AGENT_COMMERCE.PRODUCTS.PRODUCTS;  -- should be ~500+
```

## Cleanup

```sql
USE ROLE ACCOUNTADMIN;
DROP DATABASE IF EXISTS AGENT_COMMERCE CASCADE;
DROP WAREHOUSE IF EXISTS AGENT_COMMERCE_WH;
DROP COMPUTE POOL IF EXISTS AGENT_COMMERCE_POOL;
DROP INTEGRATION IF EXISTS github_api_integration;
DROP ROLE IF EXISTS AGENT_COMMERCE_ROLE;
```
