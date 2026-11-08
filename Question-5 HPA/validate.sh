#!/usr/bin/env bash
# ==============================================================================
# validate.sh - Question 5: HPA
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

echo "=== Validating: Question-5 HPA ==="

HPA="apache-server"
NS="autoscale"

# 1. HPA exists
if kubectl get hpa "$HPA" -n "$NS" >/dev/null 2>&1; then
  pass "HPA '$HPA' exists in namespace '$NS'"
else
  fail "HPA '$HPA' not found in namespace '$NS'"
  echo "Summary: $PASSED/$TOTAL tests passed"
  exit 1
fi

# 2. Target deployment
TARGET=$(kubectl get hpa "$HPA" -n "$NS" -o jsonpath='{.spec.scaleTargetRef.name}' 2>/dev/null || echo "")
if [[ "$TARGET" == "apache-deployment" ]]; then
  pass "HPA targets 'apache-deployment'"
else
  fail "Expected target 'apache-deployment', got '$TARGET'"
fi

# 3. Min / Max replicas
MIN_REP=$(kubectl get hpa "$HPA" -n "$NS" -o jsonpath='{.spec.minReplicas}' 2>/dev/null || echo "")
MAX_REP=$(kubectl get hpa "$HPA" -n "$NS" -o jsonpath='{.spec.maxReplicas}' 2>/dev/null || echo "")
if [[ "$MIN_REP" -eq 1 && "$MAX_REP" -eq 4 ]]; then
  pass "Replicas configured: min=1, max=4"
else
  fail "Replica bounds incorrect" "min='$MIN_REP' (expected 1), max='$MAX_REP' (expected 4)"
fi

# 4. Target CPU utilization 50%
CPU_UTIL=$(kubectl get hpa "$HPA" -n "$NS" -o jsonpath='{.spec.metrics[?(@.resource.name=="cpu")].resource.target.averageUtilization}' 2>/dev/null || echo "")
if [[ "$CPU_UTIL" -eq 50 ]]; then
  pass "CPU target utilization is 50%"
else
  fail "Target CPU utilization expected 50%, got '$CPU_UTIL%'"
fi

# 5. Downscale stabilization window 30s
STAB_WIN=$(kubectl get hpa "$HPA" -n "$NS" -o jsonpath='{.spec.behavior.scaleDown.stabilizationWindowSeconds}' 2>/dev/null || echo "")
if [[ "$STAB_WIN" -eq 30 ]]; then
  pass "ScaleDown stabilizationWindowSeconds is 30"
else
  fail "ScaleDown stabilizationWindowSeconds expected 30, got '$STAB_WIN'"
fi

echo "Summary: $PASSED/$TOTAL tests passed"
[[ $FAILED -eq 0 ]] && exit 0 || exit 1

