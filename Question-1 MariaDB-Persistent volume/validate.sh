#!/usr/bin/env bash
# ==============================================================================
# validate.sh - Question 1: MariaDB-Persistent volume
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

echo "=== Validating: Question-1 MariaDB-Persistent volume ==="

NS="mariadb"
PVC="mariadb"
PV="mariadb-pv"
DEPLOY="mariadb"

# 1. Namespace existence
if kubectl get ns "$NS" >/dev/null 2>&1; then
  pass "Namespace '$NS' exists"
else
  fail "Namespace '$NS' does not exist"
fi

# 2. PVC existence and specifications
if kubectl get pvc "$PVC" -n "$NS" >/dev/null 2>&1; then
  pass "PVC '$PVC' exists in namespace '$NS'"

  # AccessMode
  ACCESS_MODE=$(kubectl get pvc "$PVC" -n "$NS" -o jsonpath='{.spec.accessModes[0]}' 2>/dev/null || echo "")
  if [[ "$ACCESS_MODE" == "ReadWriteOnce" ]]; then
    pass "PVC accessMode is ReadWriteOnce"
  else
    fail "PVC accessMode expected 'ReadWriteOnce', got '$ACCESS_MODE'"
  fi

  # Storage request
  STORAGE_REQ=$(kubectl get pvc "$PVC" -n "$NS" -o jsonpath='{.spec.resources.requests.storage}' 2>/dev/null || echo "")
  if [[ "$STORAGE_REQ" == "250Mi" ]]; then
    pass "PVC storage request is 250Mi"
  else
    fail "PVC storage request expected '250Mi', got '$STORAGE_REQ'"
  fi

  # PVC Bound status
  PVC_STATUS=$(kubectl get pvc "$PVC" -n "$NS" -o jsonpath='{.status.phase}' 2>/dev/null || echo "")
  if [[ "$PVC_STATUS" == "Bound" ]]; then
    pass "PVC is in 'Bound' phase"
  else
    fail "PVC phase expected 'Bound', got '$PVC_STATUS'"
  fi
else
  fail "PVC '$PVC' not found in namespace '$NS'"
fi

# 3. PV binding
if kubectl get pv "$PV" >/dev/null 2>&1; then
  PV_CLAIM=$(kubectl get pv "$PV" -o jsonpath='{.spec.claimRef.name}' 2>/dev/null || echo "")
  if [[ "$PV_CLAIM" == "$PVC" ]]; then
    pass "PV '$PV' is bound to PVC '$PVC'"
  else
    fail "PV '$PV' bound claim expected '$PVC', got '$PV_CLAIM'"
  fi
else
  fail "PV '$PV' not found"
fi

# 4. Deployment configuration
if kubectl get deploy "$DEPLOY" -n "$NS" >/dev/null 2>&1; then
  pass "Deployment '$DEPLOY' exists in namespace '$NS'"

  # Check mounted volume claimName
  CLAIM_NAME=$(kubectl get deploy "$DEPLOY" -n "$NS" -o jsonpath='{.spec.template.spec.volumes[*].persistentVolumeClaim.claimName}' 2>/dev/null || echo "")
  if echo "$CLAIM_NAME" | grep -qw "$PVC"; then
    pass "Deployment mounts PVC '$PVC'"
  else
    fail "Deployment does not mount PVC '$PVC'" "Current volume claimNames: '$CLAIM_NAME'"
  fi

  # Check pod status
  READY_REPLICAS=$(kubectl get deploy "$DEPLOY" -n "$NS" -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")
  if [[ "${READY_REPLICAS:-0}" -ge 1 ]]; then
    pass "Deployment has at least 1 ready replica"
  else
    fail "Deployment has no ready replicas" "readyReplicas: '${READY_REPLICAS:-0}'"
  fi
else
  fail "Deployment '$DEPLOY' not found in namespace '$NS'"
fi

echo "Summary: $PASSED/$TOTAL tests passed"
[[ $FAILED -eq 0 ]] && exit 0 || exit 1

