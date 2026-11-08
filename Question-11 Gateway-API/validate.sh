#!/usr/bin/env bash
# ==============================================================================
# validate.sh - Question 11: Gateway-API
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

echo "=== Validating: Question-11 Gateway-API ==="

GW="web-gateway"
ROUTE="web-route"

# 1. Gateway resource
if kubectl get gateway "$GW" >/dev/null 2>&1; then
  pass "Gateway '$GW' exists"

  # GatewayClass
  GW_CLASS=$(kubectl get gateway "$GW" -o jsonpath='{.spec.gatewayClassName}' 2>/dev/null || echo "")
  if [[ "$GW_CLASS" == "nginx-class" ]]; then
    pass "Gateway uses gatewayClassName 'nginx-class'"
  else
    fail "Gateway gatewayClassName expected 'nginx-class', got '$GW_CLASS'"
  fi

  # Hostname & Port
  HOST=$(kubectl get gateway "$GW" -o jsonpath='{.spec.listeners[*].hostname}' 2>/dev/null || echo "")
  PORT=$(kubectl get gateway "$GW" -o jsonpath='{.spec.listeners[*].port}' 2>/dev/null || echo "")
  CERT=$(kubectl get gateway "$GW" -o jsonpath='{.spec.listeners[*].tls.certificateRefs[*].name}' 2>/dev/null || echo "")

  if echo "$HOST" | grep -q "gateway.web.k8s.local"; then
    pass "Gateway listener hostname includes 'gateway.web.k8s.local'"
  else
    fail "Gateway listener hostname missing 'gateway.web.k8s.local'" "Current: '$HOST'"
  fi

  if echo "$PORT" | grep -q "443"; then
    pass "Gateway listener port is 443"
  else
    fail "Gateway listener port missing 443" "Current: '$PORT'"
  fi

  if echo "$CERT" | grep -q "web-tls"; then
    pass "Gateway listener TLS references secret 'web-tls'"
  else
    fail "Gateway listener TLS missing certificateRef 'web-tls'" "Current: '$CERT'"
  fi
else
  fail "Gateway '$GW' not found"
fi

# 2. HTTPRoute resource
if kubectl get httproute "$ROUTE" >/dev/null 2>&1; then
  pass "HTTPRoute '$ROUTE' exists"

  # Parent reference
  PARENT=$(kubectl get httproute "$ROUTE" -o jsonpath='{.spec.parentRefs[*].name}' 2>/dev/null || echo "")
  if echo "$PARENT" | grep -q "$GW"; then
    pass "HTTPRoute targets parent Gateway '$GW'"
  else
    fail "HTTPRoute parentRef missing '$GW'" "Current: '$PARENT'"
  fi

  # Hostname
  R_HOST=$(kubectl get httproute "$ROUTE" -o jsonpath='{.spec.hostnames[*]}' 2>/dev/null || echo "")
  if echo "$R_HOST" | grep -q "gateway.web.k8s.local"; then
    pass "HTTPRoute hostname includes 'gateway.web.k8s.local'"
  else
    fail "HTTPRoute hostname missing 'gateway.web.k8s.local'" "Current: '$R_HOST'"
  fi

  # Backend Ref
  BACKEND=$(kubectl get httproute "$ROUTE" -o jsonpath='{.spec.rules[*].backendRefs[*].name}' 2>/dev/null || echo "")
  if echo "$BACKEND" | grep -q "web-service"; then
    pass "HTTPRoute backend references 'web-service'"
  else
    fail "HTTPRoute backendRef missing 'web-service'" "Current: '$BACKEND'"
  fi
else
  fail "HTTPRoute '$ROUTE' not found"
fi

echo "Summary: $PASSED/$TOTAL tests passed"
[[ $FAILED -eq 0 ]] && exit 0 || exit 1

