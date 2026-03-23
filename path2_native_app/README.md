# Path 2: Snowflake Native App with SPCS

Package the Agent Commerce demo as a Snowflake Native App. Consumers install with zero tooling.

## How It Works

### Provider (You)

1. Build the Application Package with bundled container image
2. Create a Marketplace listing or share privately

### Consumer

1. Click "Get" in Marketplace (or receive private share)
2. Grant 3 privileges: CREATE COMPUTE POOL, BIND SERVICE ENDPOINT, CREATE WAREHOUSE
3. The `grant_callback` automatically provisions everything

## Provider: Publish the App

### Prerequisites

- Docker image already in `AGENT_COMMERCE.UTIL.AGENT_COMMERCE_REPO`
- CSV data files in `data/csv/` directory

### Step 1: Upload Files to Stage

From SnowSQL or Snowflake CLI:

```sql
USE ROLE AGENT_COMMERCE_ROLE;
USE DATABASE AGENT_COMMERCE;
USE WAREHOUSE AGENT_COMMERCE_WH;

CREATE SCHEMA IF NOT EXISTS NATIVE_APP;
CREATE STAGE IF NOT EXISTS NATIVE_APP.APP_STAGE;

-- Upload app files
PUT file://path2_native_app/app/manifest.yml @NATIVE_APP.APP_STAGE/ AUTO_COMPRESS=FALSE OVERWRITE=TRUE;
PUT file://path2_native_app/app/setup_script.sql @NATIVE_APP.APP_STAGE/ AUTO_COMPRESS=FALSE OVERWRITE=TRUE;
PUT file://path2_native_app/app/readme.md @NATIVE_APP.APP_STAGE/ AUTO_COMPRESS=FALSE OVERWRITE=TRUE;
PUT file://path2_native_app/app/containers/service_spec.yaml @NATIVE_APP.APP_STAGE/containers/ AUTO_COMPRESS=FALSE OVERWRITE=TRUE;

-- Upload CSV data
PUT file://data/csv/*.csv @NATIVE_APP.APP_STAGE/data/ AUTO_COMPRESS=FALSE OVERWRITE=TRUE;
```

### Step 2: Create Application Package

Run `scripts/publish.sql` in Snowsight:

```sql
CREATE APPLICATION PACKAGE IF NOT EXISTS AGENT_COMMERCE_PKG;

ALTER APPLICATION PACKAGE AGENT_COMMERCE_PKG
    ADD VERSION v1
    USING '@AGENT_COMMERCE.NATIVE_APP.APP_STAGE';

ALTER APPLICATION PACKAGE AGENT_COMMERCE_PKG
    SET DEFAULT RELEASE DIRECTIVE VERSION = v1 PATCH = 0;
```

### Step 3: Test Locally

```sql
CREATE APPLICATION AGENT_COMMERCE_APP
    FROM APPLICATION PACKAGE AGENT_COMMERCE_PKG
    USING VERSION v1;

-- Grant privileges
GRANT CREATE COMPUTE POOL ON ACCOUNT TO APPLICATION AGENT_COMMERCE_APP;
GRANT BIND SERVICE ENDPOINT ON ACCOUNT TO APPLICATION AGENT_COMMERCE_APP;
GRANT CREATE WAREHOUSE ON ACCOUNT TO APPLICATION AGENT_COMMERCE_APP;

-- Verify
SHOW SERVICES IN APPLICATION AGENT_COMMERCE_APP;
```

### Step 4: Publish

- **Private sharing**: `GRANT INSTALL ON APPLICATION PACKAGE AGENT_COMMERCE_PKG TO ROLE <role>;`
- **Marketplace**: Use Snowsight > Provider Studio > Create Listing

## Consumer: Install the App

1. Find "Agent Commerce" in Marketplace or accept private share
2. Click **Get**
3. When prompted, grant:
   - CREATE COMPUTE POOL
   - BIND SERVICE ENDPOINT
   - CREATE WAREHOUSE
4. The app auto-provisions:
   - `<app_name>_POOL` compute pool (CPU_X64_S)
   - `<app_name>_WH` warehouse (X-SMALL)
   - SPCS backend service with face/skin analysis API
   - 3 Cortex Search services
5. Access the endpoint URL from: `SHOW ENDPOINTS IN SERVICE <app_name>.APP_SCHEMA.AGENT_COMMERCE_BACKEND;`

## What Gets Installed

| Component | Count | Details |
|-----------|-------|---------|
| Schemas | 6 | PRODUCTS, CUSTOMERS, INVENTORY, SOCIAL, CART_OLTP, UTIL + APP_SCHEMA |
| Tables | 31 | Including cart/order tables (converted from Hybrid for app compatibility) |
| Views | 5 | Product, label, social search content views |
| UDFs | 10 | Agent tools: face analysis, product matching, cart operations |
| Procedures | 13 | Customer mgmt, cart CRUD, embedding operations |
| Semantic Views | 5 | Cart, Customer, Inventory, Product, Social |
| Cortex Search | 3 | Product, Label, Social search services |
| Cortex Agent | 1 | AGENTIC_COMMERCE_ASSISTANT (17 tools) |
| SPCS Service | 1 | Face recognition + skin analysis backend |

## Cleanup

### Consumer
```sql
DROP APPLICATION IF EXISTS AGENT_COMMERCE_APP CASCADE;
```

### Provider
```sql
DROP APPLICATION PACKAGE IF EXISTS AGENT_COMMERCE_PKG;
DROP SCHEMA IF EXISTS AGENT_COMMERCE.NATIVE_APP;
```
