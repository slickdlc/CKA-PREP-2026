#!/usr/bin/env bash
# ==============================================================================
# show.sh - Display the question text (Questions.bash) for a given question
# ==============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Color codes
if [[ -t 1 ]] && [[ -z "${NO_COLOR:-}" ]]; then
  GREEN='\033[0;32m'
  RED='\033[0;31m'
  YELLOW='\033[1;33m'
  BLUE='\033[0;34m'
  CYAN='\033[0;36m'
  BOLD='\033[1m'
  NC='\033[0m'
else
  GREEN=''
  RED=''
  YELLOW=''
  BLUE=''
  CYAN=''
  BOLD=''
  NC=''
fi

SHOW_SOLUTION=false
LIST_ONLY=false
SHOW_ALL=false
TARGET_INPUT=""

show_help() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS] <QUESTION_NUMBER | QUESTION_NAME>

Displays the question text (Questions.bash) for the specified CKA question.

Options:
  -s, --solution      Also display the SolutionNotes.bash alongside the question
  -a, --all           Display all questions sequentially
  -l, --list          List all available questions
  -h, --help          Show this help message

Examples:
  $(basename "$0") 1                       # Show question 1
  $(basename "$0") 5                       # Show question 5
  $(basename "$0") 2 -s                    # Show question 2 and its solution notes
  $(basename "$0") "Question-12 Ingress"   # Show by full folder name
  $(basename "$0") --list                  # List all available questions
EOF
}

# Parse flags and arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      show_help
      exit 0
      ;;
    -s|--solution)
      SHOW_SOLUTION=true
      shift
      ;;
    -a|--all)
      SHOW_ALL=true
      shift
      ;;
    -l|--list)
      LIST_ONLY=true
      shift
      ;;
    -*)
      echo -e "${RED}Error: Unknown option '$1'${NC}" >&2
      show_help
      exit 1
      ;;
    *)
      if [[ -z "$TARGET_INPUT" ]]; then
        TARGET_INPUT="$1"
      else
        TARGET_INPUT="$TARGET_INPUT $1"
      fi
      shift
      ;;
  esac
done

cd "$REPO_ROOT"

# Discover and sort question directories naturally
mapfile -t ALL_DIRS < <(find . -maxdepth 1 -mindepth 1 -type d -name "Question-*" | sed 's|^\./||' | sort -V)

if [[ ${#ALL_DIRS[@]} -eq 0 ]]; then
  echo -e "${RED}Error: No Question-* directories found in ${REPO_ROOT}${NC}" >&2
  exit 1
fi

# List mode
if [[ "$LIST_ONLY" == true ]]; then
  echo -e "${BOLD}${CYAN}Available Questions:${NC}"
  for d in "${ALL_DIRS[@]}"; do
    d_num=$(echo "$d" | sed -E 's/^Question-([0-9]+).*/\1/')
    topic=$(echo "$d" | sed -E 's/^Question-[0-9]+[[:space:]]*//')
    printf "  %-3s -> %-30s (%s)\n" "$d_num" "$topic" "$d"
  done
  exit 0
fi

# Show single question helper
show_question_dir() {
  local dir="$1"
  local q_file=""

  if [[ -f "$dir/Questions.bash" ]]; then
    q_file="$dir/Questions.bash"
  elif [[ -f "$dir/question.md" ]]; then
    q_file="$dir/question.md"
  fi

  if [[ -z "$q_file" || ! -f "$q_file" ]]; then
    echo -e "${RED}Error: Questions file not found in '$dir'${NC}" >&2
    return 1
  fi

  echo -e "${BOLD}${BLUE}========================================================================================${NC}"
  echo -e "${BOLD}${CYAN}📌 ${dir}${NC}"
  echo -e "${BOLD}${BLUE}========================================================================================${NC}"
  cat "$q_file"
  echo

  if [[ "$SHOW_SOLUTION" == true ]]; then
    local s_file=""
    if [[ -f "$dir/SolutionNotes.bash" ]]; then
      s_file="$dir/SolutionNotes.bash"
    elif [[ -f "$dir/solution.md" ]]; then
      s_file="$dir/solution.md"
    fi

    if [[ -n "$s_file" && -f "$s_file" ]]; then
      echo -e "${BOLD}${GREEN}----------------------------------------------------------------------------------------${NC}"
      echo -e "${BOLD}${GREEN}💡 Solution Notes (${s_file}):${NC}"
      echo -e "${BOLD}${GREEN}----------------------------------------------------------------------------------------${NC}"
      cat "$s_file"
      echo
    else
      echo -e "${YELLOW}(No SolutionNotes.bash found in '$dir')${NC}"
    fi
  else
    if [[ -f "$dir/SolutionNotes.bash" || -f "$dir/solution.md" ]]; then
      echo -e "${YELLOW}💡 Tip: Run with '-s' or '--solution' to display the solution notes.${NC}"
    fi
  fi
}

# Show all questions mode
if [[ "$SHOW_ALL" == true ]]; then
  for d in "${ALL_DIRS[@]}"; do
    show_question_dir "$d"
    echo
  done
  exit 0
fi

# Require target parameter if not --list or --all
if [[ -z "$TARGET_INPUT" ]]; then
  echo -e "${RED}Error: Missing question number or name.${NC}" >&2
  show_help
  exit 1
fi

# Fuzzy match directory
TARGET_DIR=""
if [[ -d "$TARGET_INPUT" ]]; then
  TARGET_DIR="$TARGET_INPUT"
else
  target_clean="${TARGET_INPUT#Question-}"
  target_clean="${target_clean#0}"
  for d in "${ALL_DIRS[@]}"; do
    dir_num=$(echo "$d" | sed -E 's/^Question-([0-9]+).*/\1/')
    if [[ "$d" == "$TARGET_INPUT" || "$d" == Question-"$TARGET_INPUT" || "$dir_num" == "$target_clean" || "$d" == "$TARGET_INPUT"* ]]; then
      TARGET_DIR="$d"
      break
    fi
  done
fi

if [[ -z "$TARGET_DIR" || ! -d "$TARGET_DIR" ]]; then
  echo -e "${RED}Error: Question directory for '$TARGET_INPUT' not found in $REPO_ROOT${NC}" >&2
  echo -e "Use '${BOLD}$(basename "$0") --list${NC}' to view all available questions." >&2
  exit 1
fi

show_question_dir "$TARGET_DIR"

