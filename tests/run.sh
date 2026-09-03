#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

bash "$ROOT_DIR/tests/unit.sh"
bash "$ROOT_DIR/tests/integration.sh"

echo "All tests passed"
