# Agent Commerce Demo

AI-powered beauty shopping assistant with face recognition, skin analysis, and intelligent product recommendations. Built on Snowflake Cortex Agent, SPCS, Cortex Search, and Semantic Views.

## Architecture

```
                 +------------------+
                 |  Cortex Agent    |
                 | (17 tools)       |
                 +--------+---------+
                          |
          +---------------+---------------+
          |               |               |
    +-----+-----+  +-----+-----+  +------+------+
    | Cortex     |  | Cortex     |  | SPCS Backend |
    | Analyst    |  | Search     |  | (FastAPI)    |
    | (5 views)  |  | (3 svc)   |  | Face/Skin    |
    +-----+------+  +-----+-----+  +------+------+
          |               |               |
    +-----+------+  +-----+-----+  +------+------+
    | Semantic    |  | Products   |  | OpenCV/dlib  |
    | Views       |  | Social     |  | MediaPipe    |
    +-------------+  | Labels     |  +--------------+
                     +-----------+
```

**6 schemas** | **31 tables** | **6 views** | **13 UDFs** | **13 procedures** | **5 semantic views** | **3 search services** | **1 Cortex Agent**

## Three Deployment Paths

### Path 0: Cortex Code (Fastest)

If you have Cortex Code (CoCo) installed:

1. Install the CoCo skill (one-time):
```bash
mkdir -p ~/.snowflake/cortex/skills/deploy-agent-commerce
curl -sL https://raw.githubusercontent.com/sfc-gh-amgupta/agent_commerce_beauty_advisor/main/.snowflake/cortex/skills/deploy-agent-commerce/SKILL.md \
  -o ~/.snowflake/cortex/skills/deploy-agent-commerce/SKILL.md
```

2. Then just type in CoCo:

> deploy agent commerce demo

CoCo handles everything automatically — SQL execution, Docker image push, verification.

**Zero manual steps.** Requires Docker + ACCOUNTADMIN.

### Path 1: GitHub CI/CD (Recommended)

Best for users who want full control and visibility into all components.

1. Run **Part A** of `deploy.sql` in Snowsight (creates infra + image repo)
2. Run `pull_and_push.sh` in terminal (pushes Docker image, ~5 min)
3. Run **Part B** of `deploy.sql` in Snowsight (deploys everything)

**No fork needed. Requires Docker locally.** See [path1_github_cicd/README.md](path1_github_cicd/README.md).

### Path 2: Snowflake Native App

Best for zero-friction distribution. Consumer clicks Get, grants privileges, done.

Provider publishes once as a Native App with SPCS. Consumer installs from Marketplace or private listing.

**No tooling needed on consumer side.** See [path2_native_app/README.md](path2_native_app/README.md).

## Repository Structure

```
agent_commerce/
├── sql/                           # Shared SQL scripts (fresh from live account)
│   ├── 01_setup_infrastructure.sql
│   ├── 02_create_tables.sql
│   ├── 03_load_data.sql
│   ├── 04_create_views.sql
│   ├── 05_create_udfs_procedures.sql
│   ├── 06_create_cortex_search.sql
│   ├── 07_create_semantic_views.sql
│   ├── 08_create_agent.sql
│   └── 09_deploy_spcs.sql
├── data/csv/                      # 24 CSV seed data files (~35MB)
├── backend/                       # SPCS FastAPI backend source
├── path1_github_cicd/             # Path 1: GitHub CI/CD artifacts
│   ├── deploy.sql
│   ├── pull_and_push.sh
│   └── README.md
├── path2_native_app/              # Path 2: Native App artifacts
│   ├── app/
│   │   ├── manifest.yml
│   │   ├── setup_script.sql
│   │   ├── containers/service_spec.yaml
│   │   └── readme.md
│   ├── scripts/publish.sql
│   └── README.md
└── .github/workflows/deploy-image.yml
```

## Prerequisites

- Snowflake account with ACCOUNTADMIN access
- SPCS-supported region ([check availability](https://docs.snowflake.com/en/developer-guide/snowpark-container-services/overview#available-regions))

## Docker Image

Pre-built public image: `amitgupta392/agent-commerce-backend:latest` (~2GB)

Includes: FastAPI, OpenCV, dlib, MediaPipe for face embedding extraction and skin tone analysis.

Endpoints:
- `GET /health` - Health check
- `POST /extract-embedding` - Extract face embedding from base64 image
- `POST /analyze-skin` - Analyze skin tone from base64 image
