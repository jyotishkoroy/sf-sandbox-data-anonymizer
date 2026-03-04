# Contributing

## Local development
```bash
sf org create scratch --definition-file config/project-scratch-def.json --set-default --alias iop
sf project deploy start --source-dir force-app --target-org iop
```

## Guidelines
- Keep Apex changes covered with tests.
- Avoid org-specific assumptions (hard-coded domains, remote site settings).
- Maintain the “no custom objects” constraint.
