#!/usr/bin/env bash
# ==============================================================================
# validate.sh - Question 17: TLS-Config
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

echo "=== Validating: Question-17 TLS-Config ==="

NS="nginx-static"
CM="nginx-config"
HOST="ckaquestion.k8s.local"

# 1. ConfigMap checks
if kubectl get cm "$CM" -n "$NS" >/dev/null 2>&1; then
  pass "ConfigMap '$CM' exists in namespace '$NS'"

  CM_DATA=$(kubectl get cm "$CM" -n "$NS" -o jsonpath='{.data.nginx\.conf}' 2>/dev/null || echo "")

  if echo "$CM_DATA" | grep -q "TLSv1.3"; then
    pass "ConfigMap includes TLSv1.3"
  else
    fail "ConfigMap missing TLSv1.3 specification"
  fi

  if echo "$CM_DATA" | grep -q "TLSv1.2"; then
    fail "ConfigMap still contains TLSv1.2 (must only support TLSv1.3)"
  else
    pass "ConfigMap does not contain TLSv1.2"
  fi
else
  fail "ConfigMap '$CM' not found in namespace '$NS'"
fi

# 2. /etc/hosts entry check
if grep -q "$HOST" /etc/hosts 2>/dev/null; then
  pass "/etc/hosts contains entry for '$HOST'"
else
  fail "Missing host entry '$HOST' in /etc/hosts"
fi

echo "Summary: $PASSED/$TOTAL tests passed"
[[ $FAILED -eq 0 ]] && exit 0 || exit 1

