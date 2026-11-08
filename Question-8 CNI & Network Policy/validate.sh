#!/usr/bin/env bash
# ==============================================================================
# validate.sh - Question 8: CNI & Network Policy
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

echo "=== Validating: Question-8 CNI & Network Policy ==="

# 1. Check for active CNI pods (Calico, Flannel, Cilium, etc.)
CNI_PODS=$(kubectl get pods -A -l 'k8s-app in (flannel, calico-node, cilium)' -o jsonpath='{.items[*].metadata.name}' 2>/dev/null || echo "")
if [[ -z "$CNI_PODS" ]]; then
  # Check tigera-operator / calico-system pods
  CNI_PODS=$(kubectl get pods -n calico-system -o jsonpath='{.items[*].metadata.name}' 2>/dev/null || echo "")
fi
if [[ -z "$CNI_PODS" ]]; then
  CNI_PODS=$(kubectl get pods -n tigera-operator -o jsonpath='{.items[*].metadata.name}' 2>/dev/null || echo "")
fi

if [[ -n "$CNI_PODS" ]]; then
  pass "CNI plugin pods detected: $CNI_PODS"
else
  # Generic check: any pod with calico/flannel/cilium in name
  GENERIC_CHECK=$(kubectl get pods -A 2>/dev/null | grep -E 'calico|flannel|cilium' || echo "")
  if [[ -n "$GENERIC_CHECK" ]]; then
    pass "CNI components detected in cluster"
  else
    fail "No recognized CNI plugin pods (Calico / Flannel) found running"
  fi
fi

# 2. Check cluster nodes ready
NOT_READY_NODES=$(kubectl get nodes --no-headers 2>/dev/null | grep -v " Ready " | awk '{print $1}' || echo "")
if [[ -z "$NOT_READY_NODES" ]]; then
  pass "All cluster nodes are in 'Ready' state"
else
  fail "One or more nodes not Ready: $NOT_READY_NODES"
fi

echo "Summary: $PASSED/$TOTAL tests passed"
[[ $FAILED -eq 0 ]] && exit 0 || exit 1

