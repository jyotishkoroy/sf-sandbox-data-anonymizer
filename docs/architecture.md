# Architecture

## UI data sources
The LWC UI uses two channels:

1) **Same-origin REST/Tooling API calls** (from the browser)
- `/services/data/vXX.X/limits` for API usage & limit signals
- Tooling API queries for:
  - `NamedCredential` inventory
  - `ApexLog` for correlation browsing (optional)

2) **Apex services** (when server-side privileges or callouts are needed)
- Webhook intake endpoint (Apex REST)
- Inbox listing and file-body retrieval (ContentVersion)
- Replay via Named Credentials (Apex callouts)

## Storage strategy (no custom objects)
The webhook inbox stores each request as a **JSON file**:
- Object: `ContentVersion`
- Title: `IO_Webhook_<corrId>_<timestamp>`
- Body: JSON with headers, query params, raw body, verification result

This keeps the project deployable in any org without schema changes.
