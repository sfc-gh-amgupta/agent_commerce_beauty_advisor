-- =============================================================================
-- AGENT COMMERCE - Create Views (6 views)
-- =============================================================================
-- Extracted via GET_DDL() from live AGENT_COMMERCE database.
-- =============================================================================

USE ROLE AGENT_COMMERCE_ROLE;
USE DATABASE AGENT_COMMERCE;
USE WAREHOUSE AGENT_COMMERCE_WH;

-- ===========================================================================
-- SCHEMA: PRODUCTS (4 views)
-- ===========================================================================
USE SCHEMA PRODUCTS;

create or replace view LABEL_SEARCH_CONTENT(
	CONTENT_TYPE,
	ID,
	PRODUCT_ID,
	PRODUCT_NAME,
	TITLE,
	CONTENT,
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
) as SELECT
    'ingredient' AS content_type,
    pi.ingredient_id AS id,
    pi.product_id,
    p.name AS product_name,
    CONCAT(
        p.name,
         ' (ID:', pi.product_id, ') - Ingredient: ', pi.ingredient_name,
        ' | Label: ', COALESCE(pi.source_image_url, 'N/A')
    ) AS title,
    CONCAT(p.name, ' ', p.brand, ' ', pi.ingredient_name) AS content,
    p.brand,
    p.category,
    p.subcategory,
    pi.is_allergen,
    pi.allergen_type,
    p.current_price,
    p.is_vegan,
    p.is_cruelty_free,
    COALESCE(pi.source_image_url, 'N/A') AS label_image_url,
    NULL AS severity
FROM PRODUCTS.PRODUCT_INGREDIENTS pi
JOIN PRODUCTS.PRODUCTS p ON pi.product_id = p.product_id
WHERE p.is_active = TRUE

UNION ALL

SELECT
    'warning' AS content_type,
    pw.warning_id AS id,
    pw.product_id,
    p.name AS product_name,
    CONCAT(
        p.name,
         ' (ID:', pw.product_id, ') - Warning: ', pw.warning_text,
        ' | Label: ', COALESCE(pw.source_image_url, 'N/A')
    ) AS title,
    CONCAT(p.name, ' ', p.brand, ' ', pw.warning_text) AS content,
    p.brand,
    p.category,
    p.subcategory,
    FALSE AS is_allergen,
    NULL AS allergen_type,
    p.current_price,
    p.is_vegan,
    p.is_cruelty_free,
    COALESCE(pw.source_image_url, 'N/A') AS label_image_url,
    pw.severity
FROM PRODUCTS.PRODUCT_WARNINGS pw
JOIN PRODUCTS.PRODUCTS p ON pw.product_id = p.product_id
WHERE p.is_active = TRUE;

create or replace view PRODUCTS_QUICK_MATCH(
	PRODUCT_ID,
	NAME,
	BRAND,
	CATEGORY,
	CURRENT_PRICE,
	SKIN_TYPES,
	UNDERTONES
) as SELECT
    product_id,
    name,
    brand,
    category,
    current_price,
    ARRAY_TO_STRING(skin_type_compatibility, ', ') as skin_types,
    ARRAY_TO_STRING(undertone_compatibility, ', ') as undertones
FROM PRODUCTS
WHERE is_active = TRUE;

create or replace view PRODUCT_SEARCH_CONTENT(
	CONTENT_TYPE,
	ID,
	PRODUCT_ID,
	TITLE,
	CONTENT,
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
) as
-- Product catalog entries
SELECT
    'product' AS content_type,
    p.product_id AS id,
    p.product_id,
    p.name AS title,
    COALESCE(p.description, p.short_description, '') AS content,
    p.brand,
    p.category,
    p.subcategory,
    p.color_name,
    p.finish,
    p.current_price,
    p.is_vegan,
    p.is_cruelty_free,
    NULL AS source_image_url,
    NULL AS severity
FROM PRODUCTS p
WHERE p.is_active = TRUE

UNION ALL

-- Product label content (ingredients list, claims, directions)
SELECT
    'label' AS content_type,
    pl.label_id AS id,
    pl.product_id,
    CONCAT(p.name, ' - ', pl.label_type) AS title,
    pl.extracted_text AS content,
    p.brand,
    p.category,
    p.subcategory,
    NULL AS color_name,
    NULL AS finish,
    p.current_price,
    p.is_vegan,
    p.is_cruelty_free,
    pl.source_image_url,
    NULL AS severity
FROM PRODUCT_LABELS pl
JOIN PRODUCTS p ON pl.product_id = p.product_id
WHERE p.is_active = TRUE

UNION ALL

-- Individual ingredients (for allergen/ingredient searches)
SELECT
    'ingredient' AS content_type,
    pi.ingredient_id AS id,
    pi.product_id,
    CONCAT(p.name, ' - Ingredient: ', pi.ingredient_name) AS title,
    CONCAT(
        pi.ingredient_name,
        COALESCE(' (' || pi.ingredient_name_normalized || ')', ''),
        CASE WHEN pi.is_allergen THEN ' [ALLERGEN: ' || COALESCE(pi.allergen_type, 'unknown') || ']' ELSE '' END
    ) AS content,
    p.brand,
    p.category,
    p.subcategory,
    NULL AS color_name,
    NULL AS finish,
    p.current_price,
    p.is_vegan,
    p.is_cruelty_free,
    pi.source_image_url,
    NULL AS severity
FROM PRODUCT_INGREDIENTS pi
JOIN PRODUCTS p ON pi.product_id = p.product_id
WHERE p.is_active = TRUE

UNION ALL

-- Product warnings
SELECT
    'warning' AS content_type,
    pw.warning_id AS id,
    pw.product_id,
    CONCAT(p.name, ' - Warning') AS title,
    pw.warning_text AS content,
    p.brand,
    p.category,
    p.subcategory,
    NULL AS color_name,
    NULL AS finish,
    p.current_price,
    p.is_vegan,
    p.is_cruelty_free,
    pw.source_image_url,
    pw.severity
FROM PRODUCT_WARNINGS pw
JOIN PRODUCTS p ON pw.product_id = p.product_id
WHERE p.is_active = TRUE;

create or replace view PRODUCT_SEARCH_CONTENT_BACKUP(
	CONTENT_TYPE,
	ID,
	PRODUCT_ID,
	TITLE,
	CONTENT,
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
) as SELECT * FROM PRODUCT_SEARCH_CONTENT;

-- ===========================================================================
-- SCHEMA: SOCIAL (1 view)
-- ===========================================================================
USE SCHEMA SOCIAL;

create or replace view SOCIAL_SEARCH_CONTENT(
	CONTENT_TYPE,
	ID,
	PRODUCT_ID,
	TITLE,
	CONTENT,
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
) as
-- Product reviews
SELECT
    'review' AS content_type,
    r.review_id AS id,
    r.product_id,
    r.title,
    COALESCE(r.review_text, '') AS content,
    r.review_url AS url,
    NULL AS author_handle,
    NULL AS author_name,
    r.platform,
    r.rating,
    r.helpful_votes AS engagement_score,
    r.verified_purchase,
    r.reviewer_skin_tone AS skin_tone,
    r.reviewer_skin_type AS skin_type,
    r.reviewer_undertone AS undertone,
    NULL AS sentiment_label,
    NULL AS is_sponsored,
    r.created_at AS posted_at
FROM PRODUCT_REVIEWS r
WHERE r.is_approved = TRUE

UNION ALL

-- Social media mentions
SELECT
    'social_mention' AS content_type,
    m.mention_id AS id,
    m.product_id,
    NULL AS title,
    COALESCE(m.content_text, '') AS content,
    m.post_url AS url,
    m.author_handle,
    m.author_name,
    m.platform,
    NULL AS rating,
    (m.likes + m.comments + m.shares) AS engagement_score,
    NULL AS verified_purchase,
    NULL AS skin_tone,
    NULL AS skin_type,
    NULL AS undertone,
    m.sentiment_label,
    NULL AS is_sponsored,
    m.posted_at
FROM SOCIAL_MENTIONS m

UNION ALL

-- Influencer content
SELECT
    'influencer' AS content_type,
    i.mention_id AS id,
    i.product_id,
    CONCAT(i.influencer_name, ' on ', i.platform) AS title,
    COALESCE(i.content_text, '') AS content,
    i.post_url AS url,
    i.influencer_handle AS author_handle,
    i.influencer_name AS author_name,
    i.platform,
    NULL AS rating,
    (i.likes + i.comments + i.views) AS engagement_score,
    NULL AS verified_purchase,
    i.influencer_skin_tone AS skin_tone,
    i.influencer_skin_type AS skin_type,
    i.influencer_undertone AS undertone,
    NULL AS sentiment_label,
    i.is_sponsored,
    i.posted_at
FROM INFLUENCER_MENTIONS i;

-- ===========================================================================
-- SCHEMA: UTIL (1 view)
-- ===========================================================================
USE SCHEMA UTIL;

create or replace view ECONOMIC_INDICATORS(
	DATE,
	VARIABLE,
	VARIABLE_NAME,
	VALUE,
	UNIT,
	INDICATOR_CATEGORY,
	FREQUENCY,
	IS_SEASONALLY_ADJUSTED
) as SELECT
    DATE,
    VARIABLE,
    VARIABLE_NAME,
    VALUE,
    UNIT,
    CASE
        WHEN VARIABLE_NAME ILIKE '%CPI%' THEN 'CPI'
        WHEN VARIABLE_NAME ILIKE '%unemployment%' THEN 'Unemployment'
        WHEN VARIABLE_NAME ILIKE '%retail sales%' THEN 'Retail Sales'
        WHEN VARIABLE_NAME ILIKE '%GDP%' OR VARIABLE_NAME ILIKE '%gross domestic product%' THEN 'GDP'
        WHEN VARIABLE_NAME ILIKE '%consumer credit%' THEN 'Consumer Credit'
        WHEN VARIABLE_NAME ILIKE '%mortgage%' OR VARIABLE_NAME ILIKE '%house price%' THEN 'Housing'
        WHEN VARIABLE_NAME ILIKE '%interest rate%' OR VARIABLE_NAME ILIKE '%fed funds%' THEN 'Interest Rates'
        ELSE 'Other'
    END AS INDICATOR_CATEGORY,
    CASE
        WHEN VARIABLE_NAME ILIKE '%Monthly%' THEN 'Monthly'
        WHEN VARIABLE_NAME ILIKE '%Quarterly%' THEN 'Quarterly'
        WHEN VARIABLE_NAME ILIKE '%Annual%' THEN 'Annual'
        WHEN VARIABLE_NAME ILIKE '%Weekly%' THEN 'Weekly'
        ELSE 'Other'
    END AS FREQUENCY,
    CASE
        WHEN VARIABLE_NAME ILIKE '%seasonally adjusted%' AND VARIABLE_NAME NOT ILIKE '%not seasonally%' THEN TRUE
        ELSE FALSE
    END AS IS_SEASONALLY_ADJUSTED
FROM SNOWFLAKE_PUBLIC_DATA.PUBLIC_DATA_FREE.FINANCIAL_ECONOMIC_INDICATORS_TIMESERIES
WHERE GEO_ID = 'country/USA';
