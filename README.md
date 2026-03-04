# sf-integration-observability-pack

**Integration Observability Pack** — an object-free Salesforce LWC app for day-2 operations:
API usage signals, Named Credential inventory, webhook inbox + replay, and correlation ID patterns.

**Repository name (recommended):** `sf-integration-observability-pack`  
**Short description:** Operational dashboard for Salesforce integrations: limits, credentials, webhook inbox, replay.  
**License:** MIT

---

## Why this repo is “object-free”
Many observability tools ship custom objects and require schema changes. This project intentionally avoids that.

- No Custom Objects
- No Custom Metadata Types
- No Platform Events

The **webhook inbox** is stored as standard **Files** (`ContentVersion`) so the app deploys anywhere with minimal friction.

---

## Features

### API usage & early warning
Reads `/services/data/v55.0/limits` and highlights high utilization thresholds.

### Named Credential inventory
Read-only inventory using Tooling API `NamedCredential` query.  
If you get empty results, ensure the user has **View Setup** permission.

### Webhook inbox (inbound)
Apex REST endpoint captures inbound requests and stores them as JSON files.

Endpoint:
- `https://YOUR_DOMAIN/services/apexrest/io/webhook`

Query parameters:
- `key` (optional): webhook key for signature verification (maps to a secret in `IO_WebhookSecrets`)

Headers:
- `X-Correlation-Id` (optional): caller supplied correlation id
- `X-IO-Signature` (optional): hex HMAC-SHA256 of raw body (requires `key` + configured secret)

### Replay (outbound)
Replay captured payloads through a **Named Credential** using Apex callouts.

---

## Install

### Deploy
```bash
sf org login web --set-default --alias iop
sf project deploy start --source-dir force-app --target-org iop
```

### Post-deploy
1. Assign Permission Set: **Integration Observability Pack**
2. App Launcher → **Integration Observability Pack**
3. Open tab: **Integration Observability**

---

## Send a test webhook

Example (no signature verification):
```bash
curl -X POST \
  -H "Content-Type: application/json" \
  -H "X-Correlation-Id: demo-001" \
  -d '{"event":"ping","ts":123}' \
  https://YOUR_DOMAIN/services/apexrest/io/webhook
```

Signature verification:
1) Add a secret to `IO_WebhookSecrets` for `key=demo`.  
2) Compute signature: `hex(hmac_sha256(body, secret))`  
3) Send with header `X-IO-Signature`.

---

## Correlation IDs: Apex pattern library
```apex
String corr = IO_Correlation.get();
IO_Correlation.debugMarker('before callout');

HttpRequest r = new HttpRequest();
r.setMethod('GET');
r.setEndpoint('callout:My_Named_Credential/status');
IO_Correlation.applyTo(r);

HttpResponse res = new Http().send(r);
IO_Correlation.debugMarker('after callout');
```

Queueables:
- Generate correlation id in the parent transaction
- Pass it into your Queueable constructor
- Call `IO_Correlation.set(corrId)` in `execute()`

---

## Limitations / design choices
- Inbox storage uses Files. Sharing is governed by standard File access rules.
- Signature verification needs a server-side secret source. This repo ships a code-based provider (`IO_WebhookSecrets`) to stay schema-neutral.
- Tooling API access varies by org policy. The app degrades gracefully (inventory panes may be empty).

---

## Repo layout
- `force-app/main/default/lwc/ioApp` — UI
- `force-app/main/default/classes/IO_WebhookIntake.cls` — inbound endpoint
- `force-app/main/default/classes/IO_ReplayService.cls` — replay callouts
- `force-app/main/default/classes/IO_FileService.cls` — inbox listing + body retrieval

---

## License
MIT
