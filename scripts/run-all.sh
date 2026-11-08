#!/usr/bin/env bash
# ==============================================================================
# run-all.sh - Execute setup scripts for all CKA preparation questions
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
TARGET_QUESTIONS=()

show_help() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS] [QUESTION_NUMBERS...]

Runs the setup script (LabSetUp.bash or setup.sh) for each question in sequential order.

Options:
  -d, --dry-run       Preview scripts that would be run without executing them
  -f, --fail-fast     Stop immediately if any setup script fails (default: continue)
  -l, --list          List all discovered question directories and their setup scripts
  -h, --help          Show this help message

Arguments:
  QUESTION_NUMBERS    Optional list of question numbers or names to run (e.g., 1 3 10 or Question-1)
                      If omitted, all questions are processed.

Examples:
  $(basename "$0")                      # Run all question setups
  $(basename "$0") 1 2 5                # Run setups for Questions 1, 2, and 5
  $(basename "$0") --dry-run            # Preview all questions to run
  $(basename "$0") --fail-fast          # Abort at the first failure
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
    # Clean target string (e.g. "1" or "Question-1" or "Question-01")
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

# If --list, display and exit
if [[ "$LIST_ONLY" == true ]]; then
  echo -e "${BOLD}${CYAN}Discovered Questions:${NC}"
  for dir in "${SELECTED_DIRS[@]}"; do
    setup_file=""
    if [[ -f "$dir/LabSetUp.bash" ]]; then
      setup_file="$dir/LabSetUp.bash"
    elif [[ -f "$dir/setup.sh" ]]; then
      setup_file="$dir/setup.sh"
    fi
    if [[ -n "$setup_file" ]]; then
      echo -e "  - ${GREEN}[FOUND]${NC} $dir ($setup_file)"
    else
      echo -e "  - ${RED}[MISSING]${NC} $dir (no setup script found)"
    fi
  done
  exit 0
fi

echo -e "${BOLD}${BLUE}============================================================${NC}"
echo -e "${BOLD}${BLUE}       CKA LAB SETUP RUNNER - LAUNCHING ALL SCRIPTS         ${NC}"
echo -e "${BOLD}${BLUE}============================================================${NC}"
echo -e "Target questions: ${#SELECTED_DIRS[@]}"
echo -e "Fail-fast mode:   ${FAIL_FAST}"
echo -e "Dry run:          ${DRY_RUN}"
echo

PASSED_COUNT=0
FAILED_COUNT=0
SKIPPED_COUNT=0
declare -a RESULTS=()

for dir in "${SELECTED_DIRS[@]}"; do
  echo -e "${BOLD}${CYAN}------------------------------------------------------------${NC}"
  echo -e "${BOLD}==> Processing: ${dir}${NC}"
  echo -e "${BOLD}${CYAN}------------------------------------------------------------${NC}"

  SETUP_SCRIPT=""
  if [[ -f "$dir/LabSetUp.bash" ]]; then
    SETUP_SCRIPT="$dir/LabSetUp.bash"
  elif [[ -f "$dir/setup.sh" ]]; then
    SETUP_SCRIPT="$dir/setup.sh"
  fi

  if [[ -z "$SETUP_SCRIPT" ]]; then
    echo -e "${YELLOW}[SKIP] No setup script (LabSetUp.bash or setup.sh) found in ${dir}${NC}"
    RESULTS+=("${dir}|SKIPPED|No setup script|0s")
    SKIPPED_COUNT=$((SKIPPED_COUNT + 1))
    continue
  fi

  if [[ "$DRY_RUN" == true ]]; then
    echo -e "${BLUE}[DRY-RUN] Would execute: bash ${SETUP_SCRIPT}${NC}"
    RESULTS+=("${dir}|DRY-RUN|Skipped execution|0s")
    PASSED_COUNT=$((PASSED_COUNT + 1))
    continue
  fi

  chmod +x "$SETUP_SCRIPT"

  START_TIME=$(date +%s)
  echo -e "Running setup: ${SETUP_SCRIPT} ..."
  
  bash "$SETUP_SCRIPT"
  EXIT_CODE=$?

  END_TIME=$(date +%s)
  DURATION=$((END_TIME - START_TIME))

  if [[ $EXIT_CODE -eq 0 ]]; then
    echo -e "${GREEN}[SUCCESS] Setup completed for ${dir} (${DURATION}s)${NC}"
    RESULTS+=("${dir}|SUCCESS|Completed|${DURATION}s")
    PASSED_COUNT=$((PASSED_COUNT + 1))
  else
    echo -e "${RED}[FAILED] Setup exited with code ${EXIT_CODE} for ${dir} (${DURATION}s)${NC}"
    RESULTS+=("${dir}|FAILED|Exit code ${EXIT_CODE}|${DURATION}s")
    FAILED_COUNT=$((FAILED_COUNT + 1))

    if [[ "$FAIL_FAST" == true ]]; then
      echo -e "${RED}Aborting further execution due to --fail-fast flag.${NC}"
      break
    fi
  fi
  echo
done

# Print final summary
echo
echo -e "${BOLD}${BLUE}========================================================================================${NC}"
echo -e "${BOLD}${BLUE}                                  EXECUTION SUMMARY                                     ${NC}"
echo -e "${BOLD}${BLUE}========================================================================================${NC}"
printf "%-40s | %-10s | %-8s | %-20s\n" "QUESTION" "STATUS" "TIME" "DETAILS"
echo "----------------------------------------------------------------------------------------"

for res in "${RESULTS[@]}"; do
  IFS='|' read -r r_dir r_status r_details r_time <<< "$res"
  case "$r_status" in
    SUCCESS)
      status_display="${GREEN}SUCCESS   ${NC}"
      ;;
    FAILED)
      status_display="${RED}FAILED    ${NC}"
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
  printf "%-40s | %b | %-8s | %-20s\n" "$r_dir" "$status_display" "$r_time" "$r_details"
done

echo "----------------------------------------------------------------------------------------"
echo -e "Total: ${#SELECTED_DIRS[@]} | ${GREEN}Passed: ${PASSED_COUNT}${NC} | ${RED}Failed: ${FAILED_COUNT}${NC} | ${YELLOW}Skipped: ${SKIPPED_COUNT}${NC}"
echo -e "${BOLD}${BLUE}============================================================${NC}"

if [[ $FAILED_COUNT -gt 0 ]]; then
  exit 1
fi
exit 0
