# Usage

## CLI examples

> **Warning:** killport can terminate processes and disrupt running services.
> Review requested ports carefully and use `--dry-run` to inspect matches first.

```bash
killport --yes 3000
killport --yes 3000 8080
killport --dry-run 3000-3010
killport --yes --force 3000
killport --yes --file ./ports.yaml
```

## Confirmation and dry runs

killport asks for confirmation before terminating processes during interactive
runs. Use `--yes` or `-y` as explicit approval for automation. Use `--dry-run`
to inspect matching processes without sending signals. Non-interactive runs
must provide one of these flags.

Use `--force` when graceful `SIGTERM` shutdown is not working. This skips
`SIGTERM` and sends `SIGKILL` immediately. Use it carefully because processes
cannot handle cleanup before termination.

## Input rules

- Single port: `1..65535`
- Port range: `START-END` with `START <= END`
- File mode supports plain text or YAML-like content; numeric ports/ranges are extracted.
- A maximum of 1024 unique ports can be processed per invocation. Oversized ranges are rejected before expansion.
