# Usage

## CLI examples

```bash
killport 3000
killport 3000 8080
killport 3000-3010
killport --file ./ports.yaml
```

## Input rules

- Single port: `1..65535`
- Port range: `START-END` with `START <= END`
- File mode supports plain text or YAML-like content; numeric ports/ranges are extracted.
- A maximum of 1024 unique ports can be processed per invocation. Oversized ranges are rejected before expansion.
