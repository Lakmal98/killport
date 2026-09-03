# killport

`killport` is a production-ready Bash CLI that finds and terminates processes bound to one or more ports.
It supports single ports, ranges, and file-based input with strong validation, actionable errors, and clear exit codes.

## Features

- Accepts port arguments (`3000`, `3000-3010`) and file input (`--file ports.yaml`)
- Handles multiple processes on a single port
- Attempts graceful shutdown (`SIGTERM`) first, then force kill (`SIGKILL`) if needed
- Reports permission/sudo requirements with user-friendly messages
- Requires confirmation before termination; supports `--yes` and `--dry-run`
- Supports `--force` for immediate `SIGKILL`
- Returns stable exit codes for automation

## Requirements

- Bash
- `lsof`

## Installation

### Option 1: Build Debian package

```bash
git clone https://github.com/Lakmal98/killport.git
cd killport
make install VERSION=0.4
sudo dpkg -i killport.0.4.deb
```

### Option 2: Run directly

```bash
chmod +x killport.sh
./killport.sh --help
```

## Usage examples

**Warning:** `killport` can terminate processes and disrupt running services.
Review requested ports carefully and use `--dry-run` to inspect matches first.

```bash
killport --yes 3000
killport --yes 3000 8080 5000
killport --dry-run 3000-3010
killport --yes --force 3000
killport --yes --file ports.yaml
killport -h
killport -v
```

Interactive runs ask for confirmation before terminating processes. Use `--yes`
or `-y` for explicit non-interactive approval. Use `--dry-run` to inspect what
would be terminated without sending signals. Non-interactive runs must provide
`--yes` or `--dry-run`.

Use `--force` when graceful `SIGTERM` shutdown is not working. It sends
`SIGKILL` immediately, giving processes no opportunity to clean up.

At most 1024 unique ports can be processed in one invocation. Ranges larger than
that are rejected before expansion.

### Example input file (`ports.yaml`)

```yaml
ports:
  - 3000
  - 8080
  - 5000-5002
```

## Exit codes

- `0`: success (including "port already free")
- `64`: usage error (missing args/unknown option/missing file arg)
- `65`: invalid port value or invalid range
- `69`: required dependency unavailable (`lsof` not found)
- `77`: permission-related failure (inspect/kill requires elevated privileges)
- `1`: unexpected runtime failure

## Testing

This repository now includes a Bash test suite with unit and integration coverage.

```bash
bash tests/run.sh
# or
make test
# or
npm test
```

Coverage includes:

- Invalid input handling
- Range parsing and validation
- File-based parsing
- No process found behavior
- Graceful termination path
- Forced kill path
- Multiple processes on one port
- Permission/sudo failure handling

## Troubleshooting

### "Required command 'lsof' is not available"
Install `lsof` and rerun the command.

### "Try running with sudo"
Some processes require elevated privileges:

```bash
sudo killport 3000
```

### "Port is already free"
No action is required; this is a successful no-op state.

## Documentation site (Vercel-ready)

A VitePress docs site is scaffolded in `/docs` with SEO and GEO-aware config:

- SEO: canonical URL, Open Graph/Twitter meta, robots, sitemap
- GEO/CDN: cache-control headers configured in `vercel.json`
- Locale setup: English root locale

Deploy on Vercel using repository defaults:

- Build command: `npm run docs:build`
- Output directory: `docs/.vitepress/dist`

## Contributing

1. Fork the repository and create a focused branch for your change.
2. Make the change and add or update tests when behavior changes.
3. Run the test suite and documentation build locally:

```bash
npm test
npm run docs:build
```

4. Open a pull request with a clear summary, test results, and any relevant documentation updates.

## Tag-based release pipeline

A GitHub Actions workflow is included at:

- `.github/workflows/release-on-tag.yml`

When you push a tag like `v0.4.0`, it will:

1. Run test suite
2. Build Debian package with matching version
3. Upload artifact
4. Publish a GitHub Release with the package attached
