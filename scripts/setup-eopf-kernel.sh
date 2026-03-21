#!/usr/bin/env bash
# Installs the eopf-notebook Jupyter kernel.
# Run from anywhere after cloning the repo.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
bash "${SCRIPT_DIR}/setup-kernel.sh" \
    "eopf-notebook" \
    "eopf-notebook (py3.12)" \
    "${SCRIPT_DIR}/eopf-notebook-requirements.txt"
