#!/usr/bin/env bash
# ==============================================================================
# validate-question.sh - Validate solution for a single CKA question
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Color codes
if [[ -t 1 ]] && [[ -z "${NO_COLOR:-}" ]]; then
  GREEN='\033[0;32m'
  RED='\033[0;31m'
  YELLOW='\033[1;33m'
  BLUE='\033[0;34m'
  NC='\033[0m'
else
  GREEN=''
  RED=''
  YELLOW=''
  BLUE=''
  NC=''
fi

if [[ $# -lt 1 ]]; then
  echo -e "${RED}Usage: $(basename "$0") \"Question-XX\" [or question number]${NC}" >&2
  echo "Example: $(basename "$0") 1" >&2
  echo "Example: $(basename "$0") \"Question-1 MariaDB-Persistent volume\"" >&2
  exit 1
fi

cd "$REPO_ROOT"
INPUT="$*"

# Fuzzy match question directory
TARGET_DIR=""
if [[ -d "$INPUT" ]]; then
  TARGET_DIR="$INPUT"
else
  # Try matching prefix
  target_clean="${INPUT#Question-}"
  target_clean="${target_clean#0}"
  for d in Question-*; do
    [[ -d "$d" ]] || continue
    d_num=$(echo "$d" | sed -E 's/^Question-([0-9]+).*/\1/')
    if [[ "$d" == "$INPUT" || "$d" == Question-"$INPUT" || "$d_num" == "$target_clean" || "$d" == "$INPUT"* ]]; then
      TARGET_DIR="$d"
      break
    fi
  done
fi

if [[ -z "$TARGET_DIR" || ! -d "$TARGET_DIR" ]]; then
  echo -e "${RED}Error: Question directory for '$INPUT' not found in $REPO_ROOT${NC}" >&2
  exit 1
fi

VAL_SCRIPT=""
if [[ -f "$TARGET_DIR/validate.sh" ]]; then
  VAL_SCRIPT="$TARGET_DIR/validate.sh"
elif [[ -f "$TARGET_DIR/Validate.bash" ]]; then
  VAL_SCRIPT="$TARGET_DIR/Validate.bash"
elif [[ -f "$TARGET_DIR/validate.bash" ]]; then
  VAL_SCRIPT="$TARGET_DIR/validate.bash"
fi

if [[ -z "$VAL_SCRIPT" ]]; then
  echo -e "${RED}Error: No validation script (validate.sh) found in '$TARGET_DIR'${NC}" >&2
  exit 1
fi

chmod +x "$VAL_SCRIPT"

echo -e "${BLUE}==> Validating solution for $TARGET_DIR${NC}"
(
  cd "$TARGET_DIR"
  bash "$(basename "$VAL_SCRIPT")"
)

