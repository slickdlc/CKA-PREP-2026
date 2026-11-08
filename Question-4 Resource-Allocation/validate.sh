#!/usr/bin/env bash
# ==============================================================================
# validate.sh - Question 4: Resource-Allocation
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

echo "=== Validating: Question-4 Resource-Allocation ==="

DEPLOY="wordpress"
NS="default"

if ! kubectl get deploy "$DEPLOY" -n "$NS" >/dev/null 2>&1; then
  fail "Deployment '$DEPLOY' not found in '$NS'"
  echo "Summary: $PASSED/$TOTAL tests passed"
  exit 1
fi
pass "Deployment '$DEPLOY' exists"

# 1. Replicas == 3
REPLICAS=$(kubectl get deploy "$DEPLOY" -n "$NS" -o jsonpath='{.spec.replicas}' 2>/dev/null || echo "0")
if [[ "$REPLICAS" -eq 3 ]]; then
  pass "Deployment has spec.replicas set to 3"
else
  fail "Expected 3 replicas, found '$REPLICAS'"
fi

# 2. Check main container resources
MAIN_CPU_REQ=$(kubectl get deploy "$DEPLOY" -n "$NS" -o jsonpath='{.spec.template.spec.containers[0].resources.requests.cpu}' 2>/dev/null || echo "")
MAIN_MEM_REQ=$(kubectl get deploy "$DEPLOY" -n "$NS" -o jsonpath='{.spec.template.spec.containers[0].resources.requests.memory}' 2>/dev/null || echo "")
MAIN_CPU_LIM=$(kubectl get deploy "$DEPLOY" -n "$NS" -o jsonpath='{.spec.template.spec.containers[0].resources.limits.cpu}' 2>/dev/null || echo "")
MAIN_MEM_LIM=$(kubectl get deploy "$DEPLOY" -n "$NS" -o jsonpath='{.spec.template.spec.containers[0].resources.limits.memory}' 2>/dev/null || echo "")

if [[ -n "$MAIN_CPU_REQ" && -n "$MAIN_MEM_REQ" && -n "$MAIN_CPU_LIM" && -n "$MAIN_MEM_LIM" ]]; then
  pass "Main container has cpu/mem requests and limits configured"
else
  fail "Main container missing resource requests or limits" "cpu-req='$MAIN_CPU_REQ', mem-req='$MAIN_MEM_REQ', cpu-lim='$MAIN_CPU_LIM', mem-lim='$MAIN_MEM_LIM'"
fi

# 3. Check init container resources match main container
INIT_CPU_REQ=$(kubectl get deploy "$DEPLOY" -n "$NS" -o jsonpath='{.spec.template.spec.initContainers[0].resources.requests.cpu}' 2>/dev/null || echo "")
INIT_MEM_REQ=$(kubectl get deploy "$DEPLOY" -n "$NS" -o jsonpath='{.spec.template.spec.initContainers[0].resources.requests.memory}' 2>/dev/null || echo "")
INIT_CPU_LIM=$(kubectl get deploy "$DEPLOY" -n "$NS" -o jsonpath='{.spec.template.spec.initContainers[0].resources.limits.cpu}' 2>/dev/null || echo "")
INIT_MEM_LIM=$(kubectl get deploy "$DEPLOY" -n "$NS" -o jsonpath='{.spec.template.spec.initContainers[0].resources.limits.memory}' 2>/dev/null || echo "")

if [[ "$INIT_CPU_REQ" == "$MAIN_CPU_REQ" && "$INIT_MEM_REQ" == "$MAIN_MEM_REQ" && \
      "$INIT_CPU_LIM" == "$MAIN_CPU_LIM" && "$INIT_MEM_LIM" == "$MAIN_MEM_LIM" && -n "$INIT_CPU_REQ" ]]; then
  pass "Init container has identical resource requests and limits to main container"
else
  fail "Init container resources do not match main container" \
       "Init: cpu-req='$INIT_CPU_REQ', mem-req='$INIT_MEM_REQ' | Main: cpu-req='$MAIN_CPU_REQ', mem-req='$MAIN_MEM_REQ'"
fi

# 4. Ready replicas check
READY=$(kubectl get deploy "$DEPLOY" -n "$NS" -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")
if [[ "${READY:-0}" -eq 3 ]]; then
  pass "All 3 replicas are running and ready"
else
  fail "Not all replicas ready" "readyReplicas: '${READY:-0}'"
fi

echo "Summary: $PASSED/$TOTAL tests passed"
[[ $FAILED -eq 0 ]] && exit 0 || exit 1

