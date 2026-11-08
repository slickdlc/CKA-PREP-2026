#!/usr/bin/env bash
# ==============================================================================
# validate.sh - Question 14: Storage-Class
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

echo "=== Validating: Question-14 Storage-Class ==="

SC="local-storage"

# 1. StorageClass exists
if kubectl get sc "$SC" >/dev/null 2>&1; then
  pass "StorageClass '$SC' exists"

  # Provisioner
  PROV=$(kubectl get sc "$SC" -o jsonpath='{.provisioner}' 2>/dev/null || echo "")
  if [[ "$PROV" == "rancher.io/local-path" ]]; then
    pass "StorageClass provisioner is 'rancher.io/local-path'"
  else
    fail "Provisioner expected 'rancher.io/local-path', got '$PROV'"
  fi

  # volumeBindingMode
  MODE=$(kubectl get sc "$SC" -o jsonpath='{.volumeBindingMode}' 2>/dev/null || echo "")
  if [[ "$MODE" == "WaitForFirstConsumer" ]]; then
    pass "volumeBindingMode is 'WaitForFirstConsumer'"
  else
    fail "volumeBindingMode expected 'WaitForFirstConsumer', got '$MODE'"
  fi

  # is-default-class annotation
  IS_DEFAULT=$(kubectl get sc "$SC" -o jsonpath='{.metadata.annotations.storageclass\.kubernetes\.io/is-default-class}' 2>/dev/null || echo "")
  if [[ "$IS_DEFAULT" == "true" ]]; then
    pass "StorageClass '$SC' is marked as default"
  else
    fail "StorageClass '$SC' is not marked as default ('$IS_DEFAULT')"
  fi
else
  fail "StorageClass '$SC' not found"
fi

# 2. Ensure ONLY local-storage is default
OTHER_DEFAULTS=$(kubectl get sc -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.metadata.annotations.storageclass\.kubernetes\.io/is-default-class}{"\n"}{end}' 2>/dev/null | grep -E '\btrue\b' | grep -v "^${SC}" || echo "")

if [[ -z "$OTHER_DEFAULTS" ]]; then
  pass "'$SC' is the only default StorageClass"
else
  fail "Other StorageClass is also marked as default: $OTHER_DEFAULTS"
fi

echo "Summary: $PASSED/$TOTAL tests passed"
[[ $FAILED -eq 0 ]] && exit 0 || exit 1

