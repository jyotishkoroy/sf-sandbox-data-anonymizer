# Operational Runbook

## Recommended setup
- Create a dedicated integration user (optional) to “own” inbox files.
- Create Named Credentials for outbound endpoints.
- Optionally enable Debug Logs for the integration user if you want correlation browsing.

## Rotation / hygiene
- Treat webhook secrets like code secrets unless you implement a secure secret provider.
- Prune old inbox files periodically (standard Files retention process).
