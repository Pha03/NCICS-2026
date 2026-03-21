#!/usr/bin/env bash
# Installs the protocoast-notebook Jupyter kernel.
# Run from anywhere after cloning the repo.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
bash "${SCRIPT_DIR}/setup-kernel.sh" \
    "protocoast-notebook" \
    "protocoast-notebook (py3.12)" \
    "${SCRIPT_DIR}/protocoast-notebook-requirements.txt"
