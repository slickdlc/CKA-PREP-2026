#!/usr/bin/env bash
# ==============================================================================
# validate.sh - Question 13: Network-Policy
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

echo "=== Validating: Question-13 Network-Policy ==="

NS="backend"

# 1. NetworkPolicy in backend namespace
NETPOLS=$(kubectl get networkpolicy -n "$NS" --no-headers -o custom-columns=":metadata.name" 2>/dev/null || echo "")

if [[ -n "$NETPOLS" ]]; then
  pass "Found NetworkPolicy in namespace '$NS': $NETPOLS"

  VALID_POLICY_FOUND=false
  for pol in $NETPOLS; do
    # Check if target is backend pods
    TARGET_APP=$(kubectl get networkpolicy "$pol" -n "$NS" -o jsonpath='{.spec.podSelector.matchLabels.app}' 2>/dev/null || echo "")
    INGRESS_RULE=$(kubectl get networkpolicy "$pol" -n "$NS" -o jsonpath='{.spec.ingress}' 2>/dev/null || echo "")

    if [[ "$TARGET_APP" == "backend" ]] && echo "$INGRESS_RULE" | grep -q "frontend"; then
      VALID_POLICY_FOUND=true
      pass "Policy '$pol' correctly restricts backend access to frontend"
      break
    fi
  done

  if [[ "$VALID_POLICY_FOUND" == false ]]; then
    fail "None of the deployed network policies correctly isolate backend to frontend pods"
  fi
else
  fail "No NetworkPolicy deployed in namespace '$NS'"
fi

echo "Summary: $PASSED/$TOTAL tests passed"
[[ $FAILED -eq 0 ]] && exit 0 || exit 1

