# Troubleshooting

## Permission errors

If process termination fails with permission errors, run:

```bash
sudo killport <port>
```

## No process found

If a port is already free, killport exits successfully and reports that no process is using it.

## Verify setup

```bash
command -v lsof
bash tests/run.sh
```
