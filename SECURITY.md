# Security Policy

## Reporting a Vulnerability
If you discover a security issue:
1. Do not publish details in a public issue.
2. Open a minimal GitHub issue requesting private coordination, or contact the maintainer.

## Security design notes
- Apex classes run `with sharing`
- Webhook bodies are stored as Files (ContentVersion) and inherit standard file access controls
- Replay uses Named Credentials (recommended) to avoid hard-coded endpoints
- Signature verification is supported via HMAC-SHA256 using a server-side secret provider (no custom objects)
