# killport

`killport` is a production-ready Bash CLI that finds and terminates processes bound to one or more ports.
It supports single ports, ranges, and file-based input with strong validation, actionable errors, and clear exit codes.

## Features

- Accepts port arguments (`3000`, `3000-3010`) and file input (`--file ports.yaml`)
- Handles multiple processes on a single port
- Attempts graceful shutdown (`SIGTERM`) first, then force kill (`SIGKILL`) if needed
- Reports permission/sudo requirements with user-friendly messages
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

```bash
killport 3000
killport 3000 8080 5000
killport 3000-3010
killport --file ports.yaml
killport -h
killport -v
```

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
- Locale setup: default and `/en/` locale routes

Deploy on Vercel using repository defaults:

- Build command: `npm run docs:build`
- Output directory: `docs/.vitepress/dist`

## Tag-based release pipeline

A GitHub Actions workflow is included at:

- `.github/workflows/release-on-tag.yml`

When you push a tag like `v0.4.0`, it will:

1. Run test suite
2. Build Debian package with matching version
3. Upload artifact
4. Publish a GitHub Release with the package attached
