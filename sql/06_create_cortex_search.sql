-- =============================================================================
-- AGENT COMMERCE - Create Cortex Search Services (3 services)
-- =============================================================================
-- Extracted from SHOW CORTEX SEARCH SERVICES output.
-- =============================================================================

USE ROLE AGENT_COMMERCE_ROLE;
USE DATABASE AGENT_COMMERCE;
USE WAREHOUSE AGENT_COMMERCE_WH;

-- ===========================================================================
-- 1. PRODUCT_SEARCH_SERVICE (PRODUCTS schema)
-- ===========================================================================
USE SCHEMA PRODUCTS;

CREATE OR REPLACE CORTEX SEARCH SERVICE PRODUCT_SEARCH_SERVICE
    ON CONTENT
    ATTRIBUTES
        CONTENT_TYPE,
        ID,
        PRODUCT_ID,
        TITLE,
        BRAND,
        CATEGORY,
        SUBCATEGORY,
        COLOR_NAME,
        FINISH,
        CURRENT_PRICE,
        IS_VEGAN,
        IS_CRUELTY_FREE,
        SOURCE_IMAGE_URL,
        SEVERITY
    WAREHOUSE = AGENT_COMMERCE_WH
    TARGET_LAG = '1 hour'
    EMBEDDING_MODEL = 'snowflake-arctic-embed-m-v1.5'
    COMMENT = 'Unified search across products, labels, ingredients, and warnings'
AS (
    SELECT
        content_type,
        id,
        product_id,
        title,
        content,
        brand,
        category,
        subcategory,
        color_name,
        finish,
        current_price,
        is_vegan,
        is_cruelty_free,
        source_image_url,
        severity
    FROM PRODUCT_SEARCH_CONTENT
);

-- ===========================================================================
-- 2. LABEL_SEARCH_SERVICE (PRODUCTS schema)
-- ===========================================================================

CREATE OR REPLACE CORTEX SEARCH SERVICE LABEL_SEARCH_SERVICE
    ON CONTENT
    ATTRIBUTES
        CONTENT_TYPE,
        ID,
        PRODUCT_ID,
        PRODUCT_NAME,
        TITLE,
        BRAND,
        CATEGORY,
        SUBCATEGORY,
        IS_ALLERGEN,
        ALLERGEN_TYPE,
        CURRENT_PRICE,
        IS_VEGAN,
        IS_CRUELTY_FREE,
        LABEL_IMAGE_URL,
        SEVERITY
    WAREHOUSE = AGENT_COMMERCE_WH
    TARGET_LAG = '1 hour'
    EMBEDDING_MODEL = 'snowflake-arctic-embed-m-v1.5'
    COMMENT = 'Focused search for product label content. Title field contains embedded label_image_url for agent extraction.'
AS (
    SELECT
        content_type,
        id,
        product_id,
        product_name,
        title,
        content,
        brand,
        category,
        subcategory,
        is_allergen,
        allergen_type,
        current_price,
        is_vegan,
        is_cruelty_free,
        label_image_url,
        severity
    FROM LABEL_SEARCH_CONTENT
);

-- ===========================================================================
-- 3. SOCIAL_SEARCH_SERVICE (SOCIAL schema)
-- ===========================================================================
USE SCHEMA SOCIAL;

CREATE OR REPLACE CORTEX SEARCH SERVICE SOCIAL_SEARCH_SERVICE
    ON CONTENT
    ATTRIBUTES
        CONTENT_TYPE,
        ID,
        PRODUCT_ID,
        TITLE,
        URL,
        AUTHOR_HANDLE,
        AUTHOR_NAME,
        PLATFORM,
        RATING,
        ENGAGEMENT_SCORE,
        VERIFIED_PURCHASE,
        SKIN_TONE,
        SKIN_TYPE,
        UNDERTONE,
        SENTIMENT_LABEL,
        IS_SPONSORED,
        POSTED_AT
    WAREHOUSE = AGENT_COMMERCE_WH
    TARGET_LAG = '1 hour'
    EMBEDDING_MODEL = 'snowflake-arctic-embed-m-v1.5'
    COMMENT = 'Unified search across reviews, social mentions, and influencer content'
AS (
    SELECT
        content_type,
        id,
        product_id,
        title,
        content,
        url,
        author_handle,
        author_name,
        platform,
        rating,
        engagement_score,
        verified_purchase,
        skin_tone,
        skin_type,
        undertone,
        sentiment_label,
        is_sponsored,
        posted_at
    FROM SOCIAL_SEARCH_CONTENT
);
