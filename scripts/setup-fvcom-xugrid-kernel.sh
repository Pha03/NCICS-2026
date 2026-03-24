#!/usr/bin/env bash
# Installs the fvcom-xugrid Jupyter kernel.
# Run from anywhere after cloning the repo.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
bash "${SCRIPT_DIR}/setup-kernel.sh" \
    "fvcom-xugrid" \
    "fvcom-xugrid (py3.12)" \
    "${SCRIPT_DIR}/fvcom-xugrid-requirements.txt"
