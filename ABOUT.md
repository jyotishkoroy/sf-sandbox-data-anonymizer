# Integration Observability Pack

A compact Salesforce “ops toolkit” for integration teams: outbound callouts, Named Credentials, webhook intake, and API usage health.

This repo is intentionally **object-free** (no custom objects or custom metadata types).  
Storage for the webhook inbox uses standard **Files** (`ContentVersion`) so you can deploy it anywhere without schema changes.

Highlights:
- API usage and limit early warnings
- Named Credential inventory (read-only)
- Webhook inbox + signature verification (HMAC) + replay through Named Credentials
- Correlation ID helpers for callouts / queueables (pattern library)

See README.md for installation + operational notes.
