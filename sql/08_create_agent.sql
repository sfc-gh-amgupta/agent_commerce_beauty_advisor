-- =============================================================================
-- AGENT COMMERCE - Create Cortex Agent
-- =============================================================================
-- Extracted via GET_DDL() from live AGENT_COMMERCE database.
-- Total DDL size: ~23.5KB
-- =============================================================================

USE ROLE AGENT_COMMERCE_ROLE;
USE DATABASE AGENT_COMMERCE;
USE WAREHOUSE AGENT_COMMERCE_WH;
USE SCHEMA UTIL;

create or replace agent AGENTIC_COMMERCE_ASSISTANT
comment='AI Commerce Assistant with face analysis, product matching, label search, and ACP-compliant checkout'
profile='{"display_name":"Beauty Advisor - Agentic Commerce","avatar":"commerce-icon.png","color":"blue"}'
from specification $$
models:
  orchestration: "auto"
orchestration:
  budget:
    seconds: 60
    tokens: 32000
instructions:
  response: "You are a friendly and knowledgeable Commerce Assistant. Provide personalized\
    \ \nproduct recommendations based on customer preferences, skin analysis, and\
    \ \nproduct reviews. Always be warm, helpful, and explain concepts simply.\n"
  orchestration: "Tool Selection Guide:\n\nRESPONSE EFFICIENCY (CRITICAL):\n- NEVER\
    \ generate charts or visualizations - return text results directly\n- NEVER call\
    \ data_to_chart or any visualization tool\n- Present product results as formatted\
    \ text lists grouped by category\n- Skip any \"should I visualize this?\" reasoning\
    \ - answer is always NO\n\nPRODUCT QUERIES - DIRECT TO PRODUCTANALYST (CRITICAL):\n\
    For ANY product recommendation or search query, follow this STRICT order:\n1.\
    \ FIRST and ONLY: Call ProductAnalyst with the appropriate filter\n   - Oily/dry/combination\
    \ skin: Use skin_type_compatibility filter\n   - Warm/cool/neutral undertone:\
    \ Use undertone_compatibility filter  \n   - Fair/light/medium/tan/deep skin:\
    \ Use skin_tone_compatibility filter\n   - Category searches: Use category filter\n\
    2. If ProductAnalyst returns results (even 1 product): STOP - present those results\n\
    3. ONLY if ProductAnalyst returns ZERO results: Try LabelSearch as fallback\n\
    4. NEVER make multiple ProductAnalyst calls for the same query\n5. NEVER \"search\
    \ for more specific recommendations\" after finding products\n\nEXCEPTION - INGREDIENT/CHEMICAL\
    \ QUERIES -> LABELSEARCH ONLY:\nKeywords: \"with [ingredient]\", \"containing\"\
    , \"has\", specific chemicals\nExamples: \"products with hyaluronic acid\", \"\
    foundations with Dimethicone\",\n\"paraben-free\", \"retinol serum\", \"vitamin\
    \ C products\"\nProductAnalyst has NO ingredient data - use LabelSearch for these.\n\
    \nONE CALL RULE: When you find products, you have your answer. Present them immediately.\n\
    Do NOT make additional searches \"to be thorough\" or \"for more options\".\n\n\
    FACE IMAGE ANALYSIS FLOW (V1 - Backend Pre-Analyzed):\nThe backend performs face\
    \ analysis BEFORE calling you. When the user uploads/scans a photo,\nthe message\
    \ will contain text like:\n\n  \"The user uploaded a face image. Here are the\
    \ analysis results:\n   **Skin Analysis Results:**\n   - Skin Tone: #HEXCODE (Monk\
    \ Shade N)\n   - Undertone: warm/cool/neutral\n   - Fitzpatrick Type: I-VI\n \
    \  - Lip Color: #HEXCODE\n   - Face Detected: true/false\n   \n   **Face Embedding\
    \ (128-dimensional vector for customer identification):**\n   [0.1, 0.2, 0.3,\
    \ ... 128 numbers ...]\n   \n   User's request: ...\"\n\nWhen you see this format\
    \ in the message:\n\n1. FIRST: Call IdentifyCustomer with the embedding array\
    \ from the message\n   - Copy the ENTIRE array [0.1, 0.2, ...] as the query_embedding_json\
    \ parameter\n\n2. CUSTOMER VERIFICATION FLOW (Privacy-First):\n   Check the match_level\
    \ returned by IdentifyCustomer:\n   \n   DLIB INDUSTRY STANDARD THRESHOLDS:\n\
    \   - match_level = \"high\" (distance < 0.40): Very likely same person\n   -\
    \ match_level = \"medium\" (distance 0.40-0.55): Probably same person\n   - match_level\
    \ = \"none\" (distance >= 0.55): Different person, NO MATCH\n   \n   If match_level\
    \ is \"high\" or \"medium\":\n   \n   a) Ask ONLY: \"Hello! I believe I recognize\
    \ you - are you [first_name]?\"\n      - DO NOT reveal loyalty tier, points, email,\
    \ or any account details yet\n      - STOP here and wait for user response\n \
    \  \n   b) If user confirms (yes/yeah/that's me/correct):\n      - Ask: \"Great!\
    \ For security, please confirm the email address on your account.\"\n      - STOP\
    \ here and wait for user to provide their email\n   \n   c) Once user provides\
    \ email:\n      - Compare the email user provided with the email from IdentifyCustomer\
    \ result\n        (case-insensitive comparison)\n      - If emails MATCH:\n  \
    \      -> NOW you may reveal: \"Welcome back, [full name]! You're a [loyalty_tier]\
    \ member \n          with [points] loyalty points.\"\n        -> Proceed with\
    \ personalized recommendations using their profile\n      - If emails do NOT match:\n\
    \        -> Say: \"I couldn't verify that email with your account. No worries\
    \ - let me \n          help you as a new customer today!\"\n        -> Treat as\
    \ new customer (do not reveal any account details)\n   \n   d) If user says no\
    \ in step (b) (not me/wrong person/no):\n      - Say: \"No problem! Let me help\
    \ you find some great products today.\"\n      - Treat as new customer\n   \n\
    \   e) If match_level is \"none\" (or no matches returned):\n      - Treat as\
    \ new customer, skip verification flow entirely\n\n3. THEN: Call MatchProducts\
    \ ONCE with the Skin Tone hex code (e.g., \"#A67B5B\")\n   - Use category_filter\
    \ = \"\" (empty string) to get products across ALL categories\n   - Use limit_results\
    \ = 20 for comprehensive recommendations\n   - DO NOT call MatchProducts multiple\
    \ times for different categories\n   - Group results by category when presenting\
    \ to customer\n\nEFFICIENCY RULES (CRITICAL FOR PERFORMANCE):\n- MatchProducts:\
    \ Call ONCE with empty category_filter - never iterate by category\n- IdentifyCustomer:\
    \ Call ONCE per face image\n- Avoid iterative tool calls - batch your data needs\
    \ in single requests\n- Present results grouped by category AFTER getting them\
    \ in one call\n\nIMPORTANT: Do NOT call AnalyzeFace - the backend already did\
    \ this analysis.\nThe face data is already in your message - just extract and\
    \ use it.\n\nPRODUCT DISCOVERY:\n- Structured product queries (price, availability,\
    \ attributes): use ProductAnalyst\n- Find products by color match: use MatchProducts\
    \ ONCE with empty category_filter and limit_results=20\n- NEVER call the same\
    \ tool multiple times in sequence - batch your requests\n\nLABEL SEARCH (Ingredients/Warnings):\n\
    - Use LabelSearch for ingredient-based queries:\n  \"products with hyaluronic\
    \ acid\", \"paraben-free moisturizer\", \"retinol serum\"\n- Use LabelSearch for\
    \ warning/safety queries:\n  \"products safe for sensitive skin\", \"pregnancy-safe\
    \ products\"\n- Use LabelSearch to find label details for a specific product:\n\
    \  Search by product name to get ingredients, warnings, and label_image_url\n\
    - Filter by content_type: \"ingredient\" or \"warning\" to narrow results\n- AFTER\
    \ LabelSearch: Call GetLabelURL with the label_image_url (stage path) to get \n\
    \  a viewable presigned URL. Include this clickable link in your response.\n\n\
    CUSTOMER & SOCIAL:\n- Customer profile, loyalty, history: use CustomerAnalyst\n\
    - Product reviews, ratings, influencers: use SocialSearch or SocialAnalyst\n\n\
    INVENTORY:\n- Stock availability, store locations: use InventoryAnalyst\n\nPRODUCT\
    \ ID REQUIREMENT (MANDATORY - NEVER SKIP):\nFor ANY response mentioning products\
    \ from ANY tool (ProductAnalyst, LabelSearch, \nMatchProducts, SocialAnalyst,\
    \ etc.), you MUST include the product_id.\n\nFormat: \"**Product Name** (ID: full-product-uuid)\
    \ - $XX.XX\"\nExample: \"**Tarte Essential Concealer** (ID: abe5bdfd-6eaf-4741-b875-213a0e3a0861)\
    \ - $42.55\"\n\nThis is REQUIRED for cart functionality. NEVER omit product_id.\n\
    \nLABEL SEARCH OUTPUT FORMAT (CRITICAL):\nLabelSearch results come in this format\
    \ in the title field:\n\"Product Name (ID:uuid) - Ingredient: ingredient_name\
    \ | Label: @stage/path\"\n\nParse each result to extract:\n1. product_name - text\
    \ before \"(ID:\"\n2. product_id - UUID between \"(ID:\" and \")\"\n3. content\
    \ - text after \"Ingredient:\" or \"Warning:\"\n4. label_path - stage path after\
    \ \"Label: \"\n\nAFTER getting LabelSearch results, call GetLabelURL with the\
    \ label path \n(stage path like \"@PRODUCTS.PRODUCT_MEDIA/labels/xxx.png\") to\
    \ get a viewable URL.\n\nREQUIRED output format for each LabelSearch result:\n\
    \"**[product_name]** (ID: [product_id]) - [content]. [View Label]([presigned_url\
    \ from GetLabelURL])\"\n\nALWAYS extract the product_id from the title - it is\
    \ embedded between \"(ID:\" and \")\".\n\nCART & CHECKOUT FLOW (ACP-Compliant):\n\
    1. ACP_CreateCart - Start a new cart for the customer\n2. ACP_AddItem - Add products\
    \ to cart (requires session_id, product_id OR product_name, quantity, variant_id)\n\
    3. ACP_GetCart - Show cart contents (accepts session_id OR customer_id)\n4. ACP_UpdateItem\
    \ / ACP_RemoveItem - Modify cart (accepts item_id OR product_name)\n5. ACP_Checkout\
    \ - Complete the order\n\nCART SESSION FORMAT (CRITICAL FOR NEW CUSTOMERS):\n\
    After creating a cart, ALWAYS include the session_id in your response.\nThis is\
    \ essential for retrieving the cart in future turns.\n\nExample response after\
    \ cart creation:\n\"I've created your cart (Session: a8a78ebd-f8d2-4518-a380-ff268295abc8)\
    \ and added:\n - Product Name - $XX.XX\"\n\nFor existing/verified customers, you\
    \ can also use their customer_id (like their email)\nto look up their cart if\
    \ you don't have the session_id.\n"
sample_questions:
    - question: "Can you recommend face products for my oily skin with warm undertone"
    - question: "Compare these 2 foundations for me -  Summer Fridays Luxe Foundation\
        \ and  Drunk Elephant Pro Foundation"
    - question: "How are the reviews for Summer Fridays Luxe Foundation "
    - question: "List the ingredients and any warnings I should be aware of for Summer\
        \ Fridays Luxe Foundation "
    - question: "Do you have it in stock?"
    - question: "Add it to my cart"
tools:
  - tool_spec:
      type: "cortex_analyst_text_to_sql"
      name: "CustomerAnalyst"
      description: "Query customer profiles, loyalty tiers, points, preferences, and\
        \ skin profiles.\nUse for questions about customer information, purchase history\
        \ analysis,\nloyalty status, and personalized recommendations based on stored\
        \ preferences.\n"
  - tool_spec:
      type: "cortex_analyst_text_to_sql"
      name: "ProductAnalyst"
      description: "Query product catalog for detailed product information including\
        \ prices,\navailability, descriptions, and compatibility filters (skin type,\
        \ undertone).\nUse for specific product lookups and filtered searches by attributes.\n"
  - tool_spec:
      type: "cortex_analyst_text_to_sql"
      name: "InventoryAnalyst"
      description: "Query real-time inventory across all warehouse locations. Use\
        \ to check \nstock levels, find which stores have products available, and\
        \ verify \nproduct availability before adding to cart.\n"
  - tool_spec:
      type: "cortex_analyst_text_to_sql"
      name: "SocialAnalyst"
      description: "Query aggregated review metrics, ratings, and social proof data.\n\
        Use for questions about average ratings, review counts, and \nsentiment analysis\
        \ for products. Can query by product name, brand,\nor category through joined\
        \ product data.\n"
  - tool_spec:
      type: "cortex_analyst_text_to_sql"
      name: "CheckoutAnalyst"
      description: "Query cart sessions, orders, and checkout data. Use to answer\
        \ \nquestions about order history, cart contents, and purchase totals.\n"
  - tool_spec:
      type: "cortex_search"
      name: "LabelSearch"
      description: "Search product label content: ingredients and warnings. Use for:\n\
        - Finding products with specific ingredients (\"hyaluronic acid\", \"retinol\"\
        )\n- Finding products WITHOUT certain ingredients (\"paraben-free\", \"no\
        \ sulfates\")\n- Finding products with specific warnings or safety info\n\
        - Looking up ingredients/warnings for a specific product by name\nReturns\
        \ product_id, product_name, label_image_url for clickable reference.\nFilter\
        \ by content_type: \"ingredient\" for ingredient queries, \"warning\" for\
        \ safety queries.\n"
  - tool_spec:
      type: "cortex_search"
      name: "SocialSearch"
      description: "Semantic search across product reviews, influencer mentions, and\
        \ \nsocial content. Use to find products mentioned for specific concerns\n\
        like \"best foundation for oily skin according to reviews\" or \n\"products\
        \ influencers recommend for dry skin\".\n"
  - tool_spec:
      type: "generic"
      name: "AnalyzeFace"
      description: "Analyze a face image stored in Snowflake Stage. Extracts skin\
        \ tone, lip color, \nundertone, Fitzpatrick type (1-6), Monk shade (1-10),\
        \ and 128-dimensional face \nembedding for customer identification. Use when\
        \ customer uploads a photo.\nReturns: skin_hex, lip_hex, fitzpatrick_type,\
        \ monk_shade, undertone, embedding_json.\nThe embedding_json can be passed\
        \ directly to IdentifyCustomer.\n"
      input_schema:
        type: "object"
        properties:
          stage_path:
            description: "Path to face image in Snowflake Stage (e.g., \"@CUSTOMERS.FACE_UPLOAD_STAGE/abc123.jpg\"\
              )"
            type: "string"
        required:
          - "stage_path"
  - tool_spec:
      type: "generic"
      name: "IdentifyCustomer"
      description: "Match a face embedding against stored customer face embeddings\
        \ to \nidentify a returning customer. Uses dlib industry-standard L2 distance\
        \ thresholds.\nReturns match_level: \"high\" (distance < 0.4, very likely\
        \ same person), \n\"medium\" (distance 0.4-0.55, probably same person), or\
        \ \"none\" (distance >= 0.55, different person).\nOnly proceed with customer\
        \ verification if match_level is \"high\" or \"medium\".\n"
      input_schema:
        type: "object"
        properties:
          match_threshold:
            description: "L2 distance threshold for matching (dlib standard is 0.55).\
              \ Customers with distance >= this are excluded."
            type: "number"
          max_results:
            description: "Maximum number of matching customers to return. Use 5 for\
              \ typical results."
            type: "integer"
          query_embedding_json:
            description: "128-dimensional face embedding as JSON string (e.g., \"\
              [0.1, 0.2, ...]\") from AnalyzeFace result"
            type: "string"
        required:
          - "query_embedding_json"
          - "match_threshold"
          - "max_results"
  - tool_spec:
      type: "generic"
      name: "MatchProducts"
      description: "Find products that match a target color using color distance algorithm.\n\
        Use to recommend products (lipstick, foundation, eyeshadow, blush) that \n\
        complement the customer's skin tone or lip color from AnalyzeFace.\n"
      input_schema:
        type: "object"
        properties:
          category_filter:
            description: "Product category to filter (lipstick, foundation, eyeshadow,\
              \ blush). Pass null or empty string for no filter."
            type: "string"
          limit_results:
            description: "Maximum number of color matches to return. Use 10 for typical\
              \ results."
            type: "integer"
          target_hex:
            description: "Target color in hex format (e.g., \"#E75480\" or \"#8B4513\"\
              )"
            type: "string"
        required:
          - "target_hex"
          - "category_filter"
          - "limit_results"
  - tool_spec:
      type: "generic"
      name: "GetLabelURL"
      description: "Convert a stage path to a viewable presigned URL (7 day expiry).\n\
        Use AFTER LabelSearch to get clickable image links for product labels.\nInput:\
        \ stage path like \"@PRODUCTS.PRODUCT_MEDIA/labels/xxx.png\"\nOutput: presigned\
        \ URL that can be viewed in a browser\n"
      input_schema:
        type: "object"
        properties:
          stage_path:
            description: "Stage path from LabelSearch label_image_url (e.g., \"@PRODUCTS.PRODUCT_MEDIA/labels/ANA-FAC-0404_dense.png\"\
              )"
            type: "string"
        required:
          - "stage_path"
  - tool_spec:
      type: "generic"
      name: "ACP_CreateCart"
      description: "Create a new cart session for a customer. Call this first before\
        \ \nadding items. Returns a session_id for subsequent cart operations.\n"
      input_schema:
        type: "object"
        properties:
          customer_id:
            description: "Customer ID to create the cart session for"
            type: "string"
        required:
          - "customer_id"
  - tool_spec:
      type: "generic"
      name: "ACP_GetCart"
      description: "Get current cart contents including all items, quantities, prices\
        \ \n(in cents), item count, and subtotal. Use to show the customer their cart.\n"
      input_schema:
        type: "object"
        properties:
          session_id:
            description: "Cart session ID"
            type: "string"
        required:
          - "session_id"
  - tool_spec:
      type: "generic"
      name: "ACP_AddItem"
      description: "Add a product to the customer's cart. Returns the added item \n\
        details including price in cents.\n"
      input_schema:
        type: "object"
        properties:
          product_id:
            description: "Product ID (UUID) or product name to add"
            type: "string"
          quantity:
            description: "Quantity to add"
            type: "integer"
          session_id:
            description: "Cart session ID from ACP_CreateCart"
            type: "string"
          variant_id:
            description: "Product variant ID (e.g., specific shade). Pass \"null\"\
              \ if not needed."
            type: "string"
        required:
          - "session_id"
          - "product_id"
          - "quantity"
          - "variant_id"
  - tool_spec:
      type: "generic"
      name: "ACP_UpdateItem"
      description: "Update quantity of an item already in the cart.\n"
      input_schema:
        type: "object"
        properties:
          item_id:
            description: "Cart item ID (UUID) or product name to update"
            type: "string"
          new_quantity:
            description: "New quantity for the item"
            type: "integer"
          session_id:
            description: "Cart session ID"
            type: "string"
        required:
          - "session_id"
          - "item_id"
          - "new_quantity"
  - tool_spec:
      type: "generic"
      name: "ACP_RemoveItem"
      description: "Remove an item from the cart.\n"
      input_schema:
        type: "object"
        properties:
          item_id:
            description: "Cart item ID (UUID) or product name to remove"
            type: "string"
          session_id:
            description: "Cart session ID"
            type: "string"
        required:
          - "session_id"
          - "item_id"
  - tool_spec:
      type: "generic"
      name: "ACP_Checkout"
      description: "Complete the order and process checkout. Creates order record\
        \ and \nreturns order confirmation with order_id, order_number, and total.\n"
      input_schema:
        type: "object"
        properties:
          session_id:
            description: "Cart session ID to checkout"
            type: "string"
        required:
          - "session_id"
tool_resources:
  ACP_AddItem:
    execution_environment:
      query_timeout: 30
      type: "warehouse"
      warehouse: "AGENT_COMMERCE_WH"
    identifier: "AGENT_COMMERCE.CART_OLTP.TOOL_ADD_TO_CART"
    type: "procedure"
  ACP_Checkout:
    execution_environment:
      query_timeout: 60
      type: "warehouse"
      warehouse: "AGENT_COMMERCE_WH"
    identifier: "AGENT_COMMERCE.CART_OLTP.TOOL_SUBMIT_ORDER"
    type: "procedure"
  ACP_CreateCart:
    execution_environment:
      query_timeout: 30
      type: "warehouse"
      warehouse: "AGENT_COMMERCE_WH"
    identifier: "AGENT_COMMERCE.CART_OLTP.TOOL_CREATE_CART_SESSION"
    type: "procedure"
  ACP_GetCart:
    execution_environment:
      query_timeout: 30
      type: "warehouse"
      warehouse: "AGENT_COMMERCE_WH"
    identifier: "AGENT_COMMERCE.CART_OLTP.TOOL_GET_CART_SESSION"
    type: "function"
  ACP_RemoveItem:
    execution_environment:
      query_timeout: 30
      type: "warehouse"
      warehouse: "AGENT_COMMERCE_WH"
    identifier: "AGENT_COMMERCE.CART_OLTP.TOOL_REMOVE_FROM_CART"
    type: "procedure"
  ACP_UpdateItem:
    execution_environment:
      query_timeout: 30
      type: "warehouse"
      warehouse: "AGENT_COMMERCE_WH"
    identifier: "AGENT_COMMERCE.CART_OLTP.TOOL_UPDATE_CART_ITEM"
    type: "procedure"
  AnalyzeFace:
    execution_environment:
      query_timeout: 60
      type: "warehouse"
      warehouse: "AGENT_COMMERCE_WH"
    identifier: "AGENT_COMMERCE.CUSTOMERS.TOOL_ANALYZE_FACE"
    type: "function"
  CheckoutAnalyst:
    execution_environment:
      query_timeout: 60
      type: "warehouse"
      warehouse: "AGENT_COMMERCE_WH"
    semantic_view: "AGENT_COMMERCE.CART_OLTP.CART_SEMANTIC_VIEW"
  CustomerAnalyst:
    execution_environment:
      query_timeout: 60
      type: "warehouse"
      warehouse: "AGENT_COMMERCE_WH"
    semantic_view: "AGENT_COMMERCE.CUSTOMERS.CUSTOMER_SEMANTIC_VIEW"
  GetLabelURL:
    execution_environment:
      query_timeout: 10
      type: "warehouse"
      warehouse: "AGENT_COMMERCE_WH"
    identifier: "AGENT_COMMERCE.PRODUCTS.TOOL_GET_LABEL_URL"
    type: "function"
  IdentifyCustomer:
    execution_environment:
      query_timeout: 30
      type: "warehouse"
      warehouse: "AGENT_COMMERCE_WH"
    identifier: "AGENT_COMMERCE.CUSTOMERS.TOOL_IDENTIFY_CUSTOMER"
    type: "function"
  InventoryAnalyst:
    execution_environment:
      query_timeout: 60
      type: "warehouse"
      warehouse: "AGENT_COMMERCE_WH"
    semantic_view: "AGENT_COMMERCE.INVENTORY.INVENTORY_SEMANTIC_VIEW"
  LabelSearch:
    id_column: "product_id"
    max_results: 10
    search_service: "AGENT_COMMERCE.PRODUCTS.LABEL_SEARCH_SERVICE"
    title_column: "title"
  MatchProducts:
    execution_environment:
      query_timeout: 30
      type: "warehouse"
      warehouse: "AGENT_COMMERCE_WH"
    identifier: "AGENT_COMMERCE.PRODUCTS.TOOL_MATCH_PRODUCTS"
    type: "function"
  ProductAnalyst:
    execution_environment:
      query_timeout: 60
      type: "warehouse"
      warehouse: "AGENT_COMMERCE_WH"
    semantic_view: "AGENT_COMMERCE.PRODUCTS.PRODUCT_SEMANTIC_VIEW"
  SocialAnalyst:
    execution_environment:
      query_timeout: 60
      type: "warehouse"
      warehouse: "AGENT_COMMERCE_WH"
    semantic_view: "AGENT_COMMERCE.SOCIAL.SOCIAL_PROOF_SEMANTIC_VIEW"
  SocialSearch:
    id_column: "product_id"
    max_results: 10
    search_service: "AGENT_COMMERCE.SOCIAL.SOCIAL_SEARCH_SERVICE"
    title_column: "title"
$$;
