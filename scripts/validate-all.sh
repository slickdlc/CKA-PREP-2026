#!/usr/bin/env bash
# ==============================================================================
# validate-all.sh - Execute validation scripts for all CKA preparation questions
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

DRY_RUN=false
FAIL_FAST=false
LIST_ONLY=false
SYNTAX_CHECK=false
TARGET_QUESTIONS=()

show_help() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS] [QUESTION_NUMBERS...]

Runs the validation script (validate.sh) for each question to verify lab solutions.

Options:
  -d, --dry-run       Preview validators that would be run without executing them
  -f, --fail-fast     Stop immediately if any validation fails (default: continue)
  -l, --list          List all discovered questions and validation script status
  -s, --syntax        Run bash syntax check (bash -n) on all scripts in the project
  -h, --help          Show this help message

Arguments:
  QUESTION_NUMBERS    Optional list of question numbers or names to validate (e.g., 1 3 10 or Question-1)
                      If omitted, all questions are processed.

Examples:
  $(basename "$0")                      # Validate all questions
  $(basename "$0") 1 2 5                # Validate Questions 1, 2, and 5
  $(basename "$0") --dry-run            # Preview validations
  $(basename "$0") --fail-fast          # Stop at first failed validation
  $(basename "$0") --syntax             # Check bash syntax of all repo scripts
EOF
}

# Parse options
while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      show_help
      exit 0
      ;;
    -d|--dry-run)
      DRY_RUN=true
      shift
      ;;
    -f|--fail-fast)
      FAIL_FAST=true
      shift
      ;;
    -l|--list)
      LIST_ONLY=true
      shift
      ;;
    -s|--syntax)
      SYNTAX_CHECK=true
      shift
      ;;
    -*)
      echo -e "${RED}Error: Unknown option '$1'${NC}" >&2
      show_help
      exit 1
      ;;
    *)
      TARGET_QUESTIONS+=("$1")
      shift
      ;;
  esac
done

cd "$REPO_ROOT"

# Syntax check mode
if [[ "$SYNTAX_CHECK" == true ]]; then
  echo -e "${BOLD}${BLUE}========================================================================================${NC}"
  echo -e "${BOLD}${BLUE}                         BASH SYNTAX VALIDATION (bash -n)                               ${NC}"
  echo -e "${BOLD}${BLUE}========================================================================================${NC}"
  SYNTAX_ERRORS=0
  TOTAL_CHECKED=0

  while IFS= read -r script_file; do
    TOTAL_CHECKED=$((TOTAL_CHECKED + 1))
    if bash -n "$script_file" 2>/dev/null; then
      echo -e "  - ${GREEN}[SYNTAX OK]${NC} $script_file"
    else
      echo -e "  - ${RED}[SYNTAX ERR]${NC} $script_file"
      bash -n "$script_file" || true
      SYNTAX_ERRORS=$((SYNTAX_ERRORS + 1))
    fi
  done < <(find . -type f \( -name "*.sh" -o -name "*.bash" \) -not -path "*/.git/*" | sort)

  echo "----------------------------------------------------------------------------------------"
  echo -e "Checked: ${TOTAL_CHECKED} scripts | ${GREEN}Valid: $((TOTAL_CHECKED - SYNTAX_ERRORS))${NC} | ${RED}Errors: ${SYNTAX_ERRORS}${NC}"
  if [[ $SYNTAX_ERRORS -gt 0 ]]; then
    exit 1
  fi
  exit 0
fi

# Discover and sort question directories naturally
mapfile -t ALL_DIRS < <(find . -maxdepth 1 -mindepth 1 -type d -name "Question-*" | sed 's|^\./||' | sort -V)

if [[ ${#ALL_DIRS[@]} -eq 0 ]]; then
  echo -e "${RED}Error: No Question-* directories found in ${REPO_ROOT}${NC}" >&2
  exit 1
fi

# Filter directories if arguments provided
SELECTED_DIRS=()
if [[ ${#TARGET_QUESTIONS[@]} -gt 0 ]]; then
  for target in "${TARGET_QUESTIONS[@]}"; do
    matched=false
    target_clean="${target#Question-}"
    target_clean="${target_clean#0}"
    for dir in "${ALL_DIRS[@]}"; do
      dir_num=$(echo "$dir" | sed -E 's/^Question-([0-9]+).*/\1/')
      if [[ "$dir" == "$target" || "$dir" == Question-"$target" || "$dir_num" == "$target_clean" || "$dir" == "$target"* ]]; then
        SELECTED_DIRS+=("$dir")
        matched=true
        break
      fi
    done
    if [[ "$matched" == false ]]; then
      echo -e "${YELLOW}Warning: No matching directory found for '$target'${NC}" >&2
    fi
  done
else
  SELECTED_DIRS=("${ALL_DIRS[@]}")
fi

if [[ ${#SELECTED_DIRS[@]} -eq 0 ]]; then
  echo -e "${RED}Error: No valid question directories selected.${NC}" >&2
  exit 1
fi

# If --list, display validation status and exit
if [[ "$LIST_ONLY" == true ]]; then
  echo -e "${BOLD}${CYAN}Discovered Questions & Validators:${NC}"
  for dir in "${SELECTED_DIRS[@]}"; do
    val_file=""
    if [[ -f "$dir/validate.sh" ]]; then
      val_file="$dir/validate.sh"
    elif [[ -f "$dir/Validate.bash" ]]; then
      val_file="$dir/Validate.bash"
    elif [[ -f "$dir/validate.bash" ]]; then
      val_file="$dir/validate.bash"
    fi

    if [[ -n "$val_file" ]]; then
      echo -e "  - ${GREEN}[VALIDATOR FOUND]${NC} $dir ($val_file)"
    else
      echo -e "  - ${YELLOW}[NO VALIDATOR]   ${NC} $dir"
    fi
  done
  exit 0
fi

echo -e "${BOLD}${BLUE}========================================================================================${NC}"
echo -e "${BOLD}${BLUE}              CKA LAB VALIDATION RUNNER - EVALUATING ALL LABS                           ${NC}"
echo -e "${BOLD}${BLUE}========================================================================================${NC}"
echo -e "Target questions: ${#SELECTED_DIRS[@]}"
echo -e "Fail-fast mode:   ${FAIL_FAST}"
echo -e "Dry run:          ${DRY_RUN}"
echo

PASSED_COUNT=0
FAILED_COUNT=0
SKIPPED_COUNT=0
declare -a RESULTS=()

for dir in "${SELECTED_DIRS[@]}"; do
  echo -e "${BOLD}${CYAN}----------------------------------------------------------------------------------------${NC}"
  echo -e "${BOLD}==> Validating: ${dir}${NC}"
  echo -e "${BOLD}${CYAN}----------------------------------------------------------------------------------------${NC}"

  VAL_SCRIPT=""
  if [[ -f "$dir/validate.sh" ]]; then
    VAL_SCRIPT="$dir/validate.sh"
  elif [[ -f "$dir/Validate.bash" ]]; then
    VAL_SCRIPT="$dir/Validate.bash"
  elif [[ -f "$dir/validate.bash" ]]; then
    VAL_SCRIPT="$dir/validate.bash"
  fi

  if [[ -z "$VAL_SCRIPT" ]]; then
    echo -e "${YELLOW}[SKIP] No validation script (validate.sh) found in ${dir}${NC}"
    RESULTS+=("${dir}|SKIPPED|No validate.sh found|0s")
    SKIPPED_COUNT=$((SKIPPED_COUNT + 1))
    continue
  fi

  if [[ "$DRY_RUN" == true ]]; then
    echo -e "${BLUE}[DRY-RUN] Would execute: bash ${VAL_SCRIPT}${NC}"
    RESULTS+=("${dir}|DRY-RUN|Skipped execution|0s")
    PASSED_COUNT=$((PASSED_COUNT + 1))
    continue
  fi

  chmod +x "$VAL_SCRIPT"

  START_TIME=$(date +%s)
  
  # Run validator inside the question directory context if needed
  (
    cd "$dir"
    bash "$(basename "$VAL_SCRIPT")"
  )
  EXIT_CODE=$?

  END_TIME=$(date +%s)
  DURATION=$((END_TIME - START_TIME))

  if [[ $EXIT_CODE -eq 0 ]]; then
    echo -e "${GREEN}[PASS] All checks passed for ${dir} (${DURATION}s)${NC}"
    RESULTS+=("${dir}|PASS|All checks passed|${DURATION}s")
    PASSED_COUNT=$((PASSED_COUNT + 1))
  else
    echo -e "${RED}[FAIL] Validation failed (code ${EXIT_CODE}) for ${dir} (${DURATION}s)${NC}"
    RESULTS+=("${dir}|FAIL|Checks failed (code ${EXIT_CODE})|${DURATION}s")
    FAILED_COUNT=$((FAILED_COUNT + 1))

    if [[ "$FAIL_FAST" == true ]]; then
      echo -e "${RED}Aborting further validation due to --fail-fast flag.${NC}"
      break
    fi
  fi
  echo
done

# Print final score summary
echo
echo -e "${BOLD}${BLUE}========================================================================================${NC}"
echo -e "${BOLD}${BLUE}                                VALIDATION SCOREBOARD                                   ${NC}"
echo -e "${BOLD}${BLUE}========================================================================================${NC}"
printf "%-40s | %-10s | %-8s | %-24s\n" "QUESTION" "STATUS" "TIME" "DETAILS"
echo "----------------------------------------------------------------------------------------"

for res in "${RESULTS[@]}"; do
  IFS='|' read -r r_dir r_status r_details r_time <<< "$res"
  case "$r_status" in
    PASS)
      status_display="${GREEN}PASS      ${NC}"
      ;;
    FAIL)
      status_display="${RED}FAIL      ${NC}"
      ;;
    SKIPPED)
      status_display="${YELLOW}SKIPPED   ${NC}"
      ;;
    DRY-RUN)
      status_display="${CYAN}DRY-RUN   ${NC}"
      ;;
    *)
      status_display="${BLUE}${r_status}${NC}"
      ;;
  esac
  printf "%-40s | %b | %-8s | %-24s\n" "$r_dir" "$status_display" "$r_time" "$r_details"
done

echo "----------------------------------------------------------------------------------------"
echo -e "Total: ${#SELECTED_DIRS[@]} | ${GREEN}Passed: ${PASSED_COUNT}${NC} | ${RED}Failed: ${FAILED_COUNT}${NC} | ${YELLOW}Skipped: ${SKIPPED_COUNT}${NC}"
echo -e "${BOLD}${BLUE}========================================================================================${NC}"

if [[ $FAILED_COUNT -gt 0 ]]; then
  exit 1
fi
exit 0

