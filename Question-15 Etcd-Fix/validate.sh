#!/usr/bin/env bash
# ==============================================================================
# validate.sh - Question 15: Etcd-Fix
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

echo "=== Validating: Question-15 Etcd-Fix ==="

MANIFEST="/etc/kubernetes/manifests/kube-apiserver.yaml"

# 1. Manifest file port check
if [[ -f "$MANIFEST" ]]; then
  if grep -E -- "--etcd-servers=.*:2379" "$MANIFEST" >/dev/null 2>&1; then
    pass "kube-apiserver manifest uses correct client port 2379 for etcd"
  else
    fail "kube-apiserver manifest does not point to port 2379"
  fi

  if grep -E -- "--etcd-servers=.*:2380" "$MANIFEST" >/dev/null 2>&1; then
    fail "kube-apiserver manifest still points to peer port 2380"
  else
    pass "No peer port 2380 found in --etcd-servers flag"
  fi
else
  # If running in environment where static pod manifest is not on host or path differs
  echo -e "${YELLOW}[INFO] Manifest '$MANIFEST' not directly accessible on this host.${NC}"
fi

# 2. Control plane responsive
if kubectl get nodes >/dev/null 2>&1; then
  pass "Kubernetes API server is healthy and responding (kubectl get nodes succeeds)"
else
  fail "Kubernetes API server is unreachable or failing"
fi

echo "Summary: $PASSED/$TOTAL tests passed"
[[ $FAILED -eq 0 ]] && exit 0 || exit 1

