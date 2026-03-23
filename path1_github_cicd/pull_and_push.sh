#!/bin/bash
# ============================================================================
# Agent Commerce - Pull from Docker Hub and Push to Snowflake
# ============================================================================
# Pulls the pre-built image from Docker Hub (public, no auth required)
# and pushes it to your Snowflake image repository.
#
# PREREQUISITES:
#   - Docker Desktop installed and running
#   - Snowflake account with AGENT_COMMERCE database created
#     (run 01_setup_infrastructure.sql first)
#
# USAGE:
#   chmod +x pull_and_push.sh && ./pull_and_push.sh
# ============================================================================

set -e

echo ""
echo "=============================================="
echo "  Agent Commerce - Image Deployment"
echo "=============================================="
echo ""

DOCKERHUB_IMAGE="amitgupta392/agent-commerce-backend:latest"

# ============================================================================
# STEP 1: Collect Snowflake Account Info
# ============================================================================

echo "Enter your Snowflake account details:"
echo ""

read -p "Snowflake Account (e.g., ORGNAME-ACCOUNTNAME): " SNOWFLAKE_ACCOUNT
read -p "Snowflake Username: " SNOWFLAKE_USER

REGISTRY=$(echo "${SNOWFLAKE_ACCOUNT}.registry.snowflakecomputing.com" | tr '[:upper:]' '[:lower:]' | tr '_' '-')
SNOWFLAKE_IMAGE="${REGISTRY}/agent_commerce/util/agent_commerce_repo/agent-commerce-backend:latest"

echo ""
echo "Configuration:"
echo "   Source: ${DOCKERHUB_IMAGE}"
echo "   Target: ${SNOWFLAKE_IMAGE}"
echo "   Username: ${SNOWFLAKE_USER}"
echo ""

# ============================================================================
# STEP 2: Pull from Docker Hub
# ============================================================================

echo "[1/4] Pulling image from Docker Hub..."
echo "      (This may take a few minutes - image is ~2GB)"
docker pull --platform linux/amd64 ${DOCKERHUB_IMAGE}
echo "      Done"
echo ""

# ============================================================================
# STEP 3: Login to Snowflake Registry
# ============================================================================

echo "[2/4] Logging into Snowflake registry..."
read -s -p "      Enter your Snowflake password: " SNOWFLAKE_PASSWORD
echo ""
echo "${SNOWFLAKE_PASSWORD}" | docker login ${REGISTRY} -u ${SNOWFLAKE_USER} --password-stdin
echo "      Done"
echo ""

# ============================================================================
# STEP 4: Tag for Snowflake
# ============================================================================

echo "[3/4] Tagging image for Snowflake..."
docker tag ${DOCKERHUB_IMAGE} ${SNOWFLAKE_IMAGE}
echo "      Done"
echo ""

# ============================================================================
# STEP 5: Push to Snowflake
# ============================================================================

echo "[4/4] Pushing to Snowflake..."
echo "      (This may take a few minutes)"
docker push ${SNOWFLAKE_IMAGE}
echo "      Done"
echo ""

# ============================================================================
# Done
# ============================================================================

echo "=============================================="
echo "  Image Deployment Complete!"
echo "=============================================="
echo ""
echo "Next: Open Snowsight and run deploy.sql"
echo ""
echo "  -- Verify image was uploaded:"
echo "  SHOW IMAGES IN IMAGE REPOSITORY AGENT_COMMERCE.UTIL.AGENT_COMMERCE_REPO;"
echo ""
