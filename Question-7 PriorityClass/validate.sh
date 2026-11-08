#!/usr/bin/env bash
# ==============================================================================
# validate.sh - Question 7: PriorityClass
# ==============================================================================
set -uo pipefail

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

TOTAL=0
PASSED=0
FAILED=0

pass() {
  echo -e "${GREEN}[PASS]${NC} $1"
  ((PASSED++))
  ((TOTAL++))
}

fail() {
  echo -e "${RED}[FAIL]${NC} $1"
  if [[ -n "${2:-}" ]]; then
    echo -e "       ${YELLOW}Detail:${NC} $2"
  fi
  ((FAILED++))
  ((TOTAL++))
}

echo "=== Validating: Question-7 PriorityClass ==="

PC_NAME="high-priority"
DEPLOY="busybox-logger"
NS="priority"

# 1. PriorityClass exists
if kubectl get priorityclass "$PC_NAME" >/dev/null 2>&1; then
  pass "PriorityClass '$PC_NAME' exists"

  # Value should be 999
  VAL=$(kubectl get priorityclass "$PC_NAME" -o jsonpath='{.value}' 2>/dev/null || echo "")
  if [[ "$VAL" -eq 999 ]]; then
    pass "PriorityClass value is 999 (one less than user-critical: 1000)"
  else
    fail "PriorityClass value expected 999, got '$VAL'"
  fi
else
  fail "PriorityClass '$PC_NAME' not found"
fi

# 2. Deployment uses high-priority
if kubectl get deploy "$DEPLOY" -n "$NS" >/dev/null 2>&1; then
  DEPLOY_PC=$(kubectl get deploy "$DEPLOY" -n "$NS" -o jsonpath='{.spec.template.spec.priorityClassName}' 2>/dev/null || echo "")
  if [[ "$DEPLOY_PC" == "$PC_NAME" ]]; then
    pass "Deployment '$DEPLOY' configured with priorityClassName '$PC_NAME'"
  else
    fail "Deployment priorityClassName expected '$PC_NAME', got '$DEPLOY_PC'"
  fi
else
  fail "Deployment '$DEPLOY' not found in namespace '$NS'"
fi

echo "Summary: $PASSED/$TOTAL tests passed"
[[ $FAILED -eq 0 ]] && exit 0 || exit 1

