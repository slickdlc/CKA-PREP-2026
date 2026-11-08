#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

if [[ $# -lt 1 ]]; then
  echo "Usage: scripts/run-question.sh <Question-XX Topic | Question-XX | number>" >&2
  echo "Example: scripts/run-question.sh 1" >&2
  echo "Example: scripts/run-question.sh \"Question-1 MariaDB-Persistent volume\"" >&2
  exit 1
fi

cd "$REPO_ROOT"
INPUT="$*"

# Fuzzy match question directory if exact path doesn't match
QUESTION_DIR=""
if [[ -d "$INPUT" ]]; then
  QUESTION_DIR="$INPUT"
else
  target_clean="${INPUT#Question-}"
  target_clean="${target_clean#0}"
  for d in Question-*; do
    [[ -d "$d" ]] || continue
    d_num=$(echo "$d" | sed -E 's/^Question-([0-9]+).*/\1/')
    if [[ "$d" == "$INPUT" || "$d" == Question-"$INPUT" || "$d_num" == "$target_clean" || "$d" == "$INPUT"* ]]; then
      QUESTION_DIR="$d"
      break
    fi
  done
fi

if [[ -z "$QUESTION_DIR" || ! -d "$QUESTION_DIR" ]]; then
  echo "Question directory for '$INPUT' not found" >&2
  exit 1
fi

SETUP="$QUESTION_DIR/LabSetUp.bash"
[[ ! -f "$SETUP" && -f "$QUESTION_DIR/setup.sh" ]] && SETUP="$QUESTION_DIR/setup.sh"

QUESTION_TEXT="$QUESTION_DIR/Questions.bash"
[[ ! -f "$QUESTION_TEXT" && -f "$QUESTION_DIR/question.md" ]] && QUESTION_TEXT="$QUESTION_DIR/question.md"

SOLUTION="$QUESTION_DIR/SolutionNotes.bash"
[[ ! -f "$SOLUTION" && -f "$QUESTION_DIR/solution.md" ]] && SOLUTION="$QUESTION_DIR/solution.md"

[[ -f "$SETUP" ]] || { echo "Missing setup script ($SETUP)" >&2; exit 1; }
[[ -f "$QUESTION_TEXT" ]] || { echo "Missing question file ($QUESTION_TEXT)" >&2; exit 1; }

chmod +x "$SETUP"

echo "==> Running lab setup for $QUESTION_DIR"
"$SETUP"

echo
echo "==> Question"
cat "$QUESTION_TEXT"

echo
if [[ -f "$SOLUTION" ]]; then
  echo "Hints: see $SOLUTION"
fi
