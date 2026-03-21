#!/usr/bin/env bash
# setup-kernel.sh — Install a Jupyter kernel from a requirements file
#
# Usage:
#   bash setup-kernel.sh <kernel-name> <display-name> <requirements-file>
#
# Examples:
#   bash setup-kernel.sh protocoast-notebook "protocoast-notebook (py3.12)" protocoast-notebook-requirements.txt
#   bash setup-kernel.sh eopf-notebook "eopf-notebook (py3.12)" eopf-notebook-requirements.txt
#
# Or use the convenience wrappers:
#   bash setup-protocoast-kernel.sh
#   bash setup-eopf-kernel.sh

set -euo pipefail

if [[ $# -lt 3 ]]; then
    echo "Usage: $0 <kernel-name> <display-name> <requirements-file>"
    exit 1
fi

KERNEL_NAME="$1"
DISPLAY_NAME="$2"
REQUIREMENTS_FILE="$3"
VENV_DIR="${HOME}/envs/${KERNEL_NAME}"

# Resolve requirements path relative to this script if not absolute
if [[ "${REQUIREMENTS_FILE}" != /* ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    REQUIREMENTS="${SCRIPT_DIR}/${REQUIREMENTS_FILE}"
else
    REQUIREMENTS="${REQUIREMENTS_FILE}"
fi

if [[ ! -f "${REQUIREMENTS}" ]]; then
    echo "Error: requirements file not found: ${REQUIREMENTS}"
    exit 1
fi

echo "==> Setting up ${KERNEL_NAME} kernel"

# ── 1. Create virtual environment ──────────────────────────────────────────
if [[ -d "${VENV_DIR}" ]]; then
    echo "    venv already exists at ${VENV_DIR}, skipping creation"
else
    echo "    Creating venv at ${VENV_DIR}"
    python3 -m venv "${VENV_DIR}"
fi

# ── 2. Upgrade pip ─────────────────────────────────────────────────────────
echo "    Upgrading pip"
"${VENV_DIR}/bin/pip" install --quiet --upgrade pip wheel

# ── 3. Install packages ────────────────────────────────────────────────────
echo "    Installing packages (this may take a few minutes)..."
"${VENV_DIR}/bin/pip" install --quiet -r "${REQUIREMENTS}"

# ── 4. Patch param to handle missing cwd at import time ───────────────────
#
# param calls os.getcwd() at class-definition time in parameters.py.
# If the Jupyter kernel starts with a non-existent working directory
# (a known Coder workspace quirk), this raises FileNotFoundError.
# We patch it to fall back to $HOME if getcwd() fails.
#
PARAM_FILE="$("${VENV_DIR}/bin/python" -c \
    "import param, pathlib; print(pathlib.Path(param.__file__).parent / 'parameters.py')" \
    2>/dev/null || true)"

if [[ -z "${PARAM_FILE}" || ! -f "${PARAM_FILE}" ]]; then
    echo "    param not installed or not found, skipping patch"
elif grep -q "_safe_getcwd" "${PARAM_FILE}"; then
    echo "    param already patched, skipping"
else
    echo "    Patching param to handle missing cwd"
    PARAM_FILE="${PARAM_FILE}" python3 - <<'PYEOF'
import pathlib, os

param_path = pathlib.Path(os.environ["PARAM_FILE"])
text = param_path.read_text()

helper = (
    "#-----------------------------------------------------------------------------\n"
    "# Path\n"
    "#-----------------------------------------------------------------------------\n"
    "\n"
    "def _safe_getcwd():\n"
    "    try:\n"
    "        return os.getcwd()\n"
    "    except FileNotFoundError:\n"
    "        return os.path.expanduser('~')\n"
    "\n"
)

old_section = "#-----------------------------------------------------------------------------\n# Path\n#-----------------------------------------------------------------------------\n"
if old_section in text and "_safe_getcwd" not in text:
    text = text.replace(old_section, helper)
    text = text.replace(
        "search_paths = List(default=[os.getcwd()],",
        "search_paths = List(default=[_safe_getcwd()],"
    )
    param_path.write_text(text)
    print("    param patched successfully")
else:
    print("    param patch not needed or already applied")
PYEOF
fi

# ── 5. Register kernel with JupyterLab ─────────────────────────────────────
echo "    Registering kernel as '${KERNEL_NAME}'"
"${VENV_DIR}/bin/python" -m ipykernel install \
    --user \
    --name "${KERNEL_NAME}" \
    --display-name "${DISPLAY_NAME}"

echo ""
echo "Done! Refresh JupyterLab and select '${DISPLAY_NAME}' from the launcher."
