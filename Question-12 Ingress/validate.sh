#!/usr/bin/env bash
# ==============================================================================
# validate.sh - Question 12: Ingress
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

echo "=== Validating: Question-12 Ingress ==="

NS="echo-sound"
SVC="echo-service"
ING="echo"

# 1. Service echo-service exists
if kubectl get svc "$SVC" -n "$NS" >/dev/null 2>&1; then
  pass "Service '$SVC' exists in namespace '$NS'"

  # Type NodePort
  SVC_TYPE=$(kubectl get svc "$SVC" -n "$NS" -o jsonpath='{.spec.type}' 2>/dev/null || echo "")
  if [[ "$SVC_TYPE" == "NodePort" ]]; then
    pass "Service type is NodePort"
  else
    fail "Service type expected 'NodePort', got '$SVC_TYPE'"
  fi

  # Port 8080
  SVC_PORT=$(kubectl get svc "$SVC" -n "$NS" -o jsonpath='{.spec.ports[0].port}' 2>/dev/null || echo "")
  if [[ "$SVC_PORT" -eq 8080 ]]; then
    pass "Service port is 8080"
  else
    fail "Service port expected 8080, got '$SVC_PORT'"
  fi
else
  fail "Service '$SVC' not found in namespace '$NS'"
fi

# 2. Ingress echo exists
if kubectl get ingress "$ING" -n "$NS" >/dev/null 2>&1; then
  pass "Ingress '$ING' exists in namespace '$NS'"

  # Host example.org
  HOST=$(kubectl get ingress "$ING" -n "$NS" -o jsonpath='{.spec.rules[0].host}' 2>/dev/null || echo "")
  if [[ "$HOST" == "example.org" ]]; then
    pass "Ingress host is 'example.org'"
  else
    fail "Ingress host expected 'example.org', got '$HOST'"
  fi

  # Path /echo
  PATH_VAL=$(kubectl get ingress "$ING" -n "$NS" -o jsonpath='{.spec.rules[0].http.paths[0].path}' 2>/dev/null || echo "")
  if [[ "$PATH_VAL" == "/echo"* ]]; then
    pass "Ingress path includes '/echo'"
  else
    fail "Ingress path expected '/echo', got '$PATH_VAL'"
  fi

  # Backend service name
  BACKEND_SVC=$(kubectl get ingress "$ING" -n "$NS" -o jsonpath='{.spec.rules[0].http.paths[0].backend.service.name}' 2>/dev/null || echo "")
  if [[ "$BACKEND_SVC" == "$SVC" ]]; then
    pass "Ingress backend points to '$SVC'"
  else
    fail "Ingress backend expected '$SVC', got '$BACKEND_SVC'"
  fi
else
  fail "Ingress '$ING' not found in namespace '$NS'"
fi

echo "Summary: $PASSED/$TOTAL tests passed"
[[ $FAILED -eq 0 ]] && exit 0 || exit 1

