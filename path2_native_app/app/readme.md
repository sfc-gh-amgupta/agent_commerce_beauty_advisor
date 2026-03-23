# Agent Commerce

AI-powered beauty shopping assistant with face recognition, skin analysis, and intelligent product recommendations.

## What This App Includes

- **SPCS Backend Service**: Face embedding extraction + skin tone analysis (FastAPI, OpenCV, dlib, MediaPipe)
- **Cortex Agent**: 17-tool AI assistant (product search, cart management, face ID, skin matching)
- **Cortex Search**: 3 search services (products, labels, social/reviews)
- **Semantic Views**: 5 semantic views for natural language analytics
- **Demo Data**: 31 tables across 6 schemas with realistic beauty product data

## Required Privileges

| Privilege | Purpose |
|-----------|---------|
| CREATE COMPUTE POOL | Run the SPCS backend container |
| BIND SERVICE ENDPOINT | Expose the API endpoint publicly |
| CREATE WAREHOUSE | Execute Cortex Search indexing and queries |

## After Installation

1. Grant the requested privileges when prompted
2. The app automatically creates a compute pool and starts the backend service
3. Access the service endpoint URL shown in the app

## Schemas

- **PRODUCTS**: Product catalog, variants, pricing, labels, ingredients, warnings
- **CUSTOMERS**: Customer profiles, face embeddings, skin analysis history
- **INVENTORY**: Stock levels, locations, transactions
- **SOCIAL**: Reviews, social mentions, influencer content
- **CART_OLTP**: Shopping cart sessions, orders (Hybrid Tables)
- **UTIL**: Agent, UDFs, procedures, search services, semantic views
