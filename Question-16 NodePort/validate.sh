#!/usr/bin/env bash
# ==============================================================================
# validate.sh - Question 16: NodePort
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

echo "=== Validating: Question-16 NodePort ==="

NS="relative"
DEPLOY="nodeport-deployment"
SVC="nodeport-service"

# 1. Deployment exists
if kubectl get deploy "$DEPLOY" -n "$NS" >/dev/null 2>&1; then
  pass "Deployment '$DEPLOY' exists in namespace '$NS'"
else
  fail "Deployment '$DEPLOY' not found in namespace '$NS'"
fi

# 2. Service exists and is NodePort
if kubectl get svc "$SVC" -n "$NS" >/dev/null 2>&1; then
  pass "Service '$SVC' exists in namespace '$NS'"

  SVC_TYPE=$(kubectl get svc "$SVC" -n "$NS" -o jsonpath='{.spec.type}' 2>/dev/null || echo "")
  if [[ "$SVC_TYPE" == "NodePort" ]]; then
    pass "Service type is NodePort"
  else
    fail "Service type expected 'NodePort', got '$SVC_TYPE'"
  fi

  PORT=$(kubectl get svc "$SVC" -n "$NS" -o jsonpath='{.spec.ports[0].port}' 2>/dev/null || echo "")
  if [[ "$PORT" -eq 80 ]]; then
    pass "Service port is 80"
  else
    fail "Service port expected 80, got '$PORT'"
  fi

  NODEPORT=$(kubectl get svc "$SVC" -n "$NS" -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null || echo "")
  if [[ "$NODEPORT" -eq 30080 ]]; then
    pass "Service nodePort is 30080"
  else
    fail "Service nodePort expected 30080, got '$NODEPORT'"
  fi

  PROTO=$(kubectl get svc "$SVC" -n "$NS" -o jsonpath='{.spec.ports[0].protocol}' 2>/dev/null || echo "")
  if [[ "$PROTO" == "TCP" ]]; then
    pass "Service protocol is TCP"
  else
    fail "Service protocol expected 'TCP', got '$PROTO'"
  fi
else
  fail "Service '$SVC' not found in namespace '$NS'"
fi

echo "Summary: $PASSED/$TOTAL tests passed"
[[ $FAILED -eq 0 ]] && exit 0 || exit 1

