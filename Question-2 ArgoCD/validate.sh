#!/usr/bin/env bash
# ==============================================================================
# validate.sh - Question 2: ArgoCD
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

echo "=== Validating: Question-2 ArgoCD ==="

# 1. Namespace argocd exists
if kubectl get ns argocd >/dev/null 2>&1; then
  pass "Namespace 'argocd' exists"
else
  fail "Namespace 'argocd' does not exist"
fi

# 2. Manifest file exists
YAML_FILE="/root/argo-helm.yaml"
if [[ -f "$YAML_FILE" && -s "$YAML_FILE" ]]; then
  pass "Manifest file '$YAML_FILE' exists and is non-empty"

  # 3. CRDs must NOT be present
  if grep -q "kind: CustomResourceDefinition" "$YAML_FILE"; then
    fail "Manifest contains CustomResourceDefinition (CRDs should NOT be installed)"
  else
    pass "CRDs are properly excluded from manifest"
  fi

  # 4. Check for Argo CD components
  if grep -qi "argocd" "$YAML_FILE" && grep -q "kind: Deployment" "$YAML_FILE"; then
    pass "Manifest contains Argo CD deployment resources"
  else
    fail "Manifest does not appear to contain valid Argo CD resources"
  fi
else
  fail "Manifest file '$YAML_FILE' missing or empty"
fi

echo "Summary: $PASSED/$TOTAL tests passed"
[[ $FAILED -eq 0 ]] && exit 0 || exit 1

