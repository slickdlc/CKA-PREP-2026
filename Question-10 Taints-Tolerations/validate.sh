#!/usr/bin/env bash
# ==============================================================================
# validate.sh - Question 10: Taints-Tolerations
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

echo "=== Validating: Question-10 Taints-Tolerations ==="

NODE="node01"

# 1. Node exists
if ! kubectl get node "$NODE" >/dev/null 2>&1; then
  # Try checking first worker node if node01 doesn't exist
  NODE=$(kubectl get nodes --no-headers -o custom-columns=":metadata.name" | grep -v "control-plane\|master" | head -n 1)
  if [[ -z "$NODE" ]]; then
    fail "Target node 'node01' not found in cluster"
    echo "Summary: $PASSED/$TOTAL tests passed"
    exit 1
  fi
fi

# 2. Check taint on node
TAINTS=$(kubectl get node "$NODE" -o jsonpath='{.spec.taints}' 2>/dev/null || echo "")
if echo "$TAINTS" | grep -q "PERMISSION" && echo "$TAINTS" | grep -q "granted" && echo "$TAINTS" | grep -q "NoSchedule"; then
  pass "Node '$NODE' has taint 'PERMISSION=granted:NoSchedule'"
else
  fail "Node '$NODE' missing required taint 'PERMISSION=granted:NoSchedule'" "Current taints: '$TAINTS'"
fi

# 3. Check for a running pod on node with matching toleration
RUNNING_PODS=$(kubectl get pods -A --field-selector spec.nodeName="$NODE",status.phase=Running --no-headers -o custom-columns=":metadata.namespace,:metadata.name" 2>/dev/null || echo "")

FOUND_TOLERATED_POD=false
while read -r ns pod_name; do
  [[ -z "$pod_name" ]] && continue
  TOLS=$(kubectl get pod "$pod_name" -n "$ns" -o jsonpath='{.spec.tolerations}' 2>/dev/null || echo "")
  if echo "$TOLS" | grep -q "PERMISSION" && echo "$TOLS" | grep -q "granted"; then
    FOUND_TOLERATED_POD=true
    pass "Pod '$pod_name' (namespace '$ns') running on '$NODE' with PERMISSION toleration"
    break
  fi
done <<< "$RUNNING_PODS"

if [[ "$FOUND_TOLERATED_POD" == false ]]; then
  fail "No running pod with toleration 'PERMISSION=granted:NoSchedule' found on '$NODE'"
fi

echo "Summary: $PASSED/$TOTAL tests passed"
[[ $FAILED -eq 0 ]] && exit 0 || exit 1

