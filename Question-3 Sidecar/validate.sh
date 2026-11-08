#!/usr/bin/env bash
# ==============================================================================
# validate.sh - Question 3: Sidecar
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

echo "=== Validating: Question-3 Sidecar ==="

DEPLOY="wordpress"
NS="default"

# 1. Deployment exists
if kubectl get deploy "$DEPLOY" -n "$NS" >/dev/null 2>&1; then
  pass "Deployment '$DEPLOY' exists in namespace '$NS'"
else
  fail "Deployment '$DEPLOY' not found in namespace '$NS'"
  echo "Summary: $PASSED/$TOTAL tests passed"
  exit 1
fi

# 2. Sidecar container exists and has image busybox:stable
SIDECAR_IMG=$(kubectl get deploy "$DEPLOY" -n "$NS" -o jsonpath='{.spec.template.spec.containers[?(@.name=="sidecar")].image}' 2>/dev/null || echo "")
if [[ "$SIDECAR_IMG" == "busybox:stable" || "$SIDECAR_IMG" == *"busybox"* ]]; then
  pass "Sidecar container exists with image '$SIDECAR_IMG'"
else
  fail "Sidecar container with image busybox:stable not found" "Current image: '$SIDECAR_IMG'"
fi

# 3. Sidecar command
CMD=$(kubectl get deploy "$DEPLOY" -n "$NS" -o jsonpath='{.spec.template.spec.containers[?(@.name=="sidecar")].command}' 2>/dev/null || echo "")
ARGS=$(kubectl get deploy "$DEPLOY" -n "$NS" -o jsonpath='{.spec.template.spec.containers[?(@.name=="sidecar")].args}' 2>/dev/null || echo "")
COMBINED="$CMD $ARGS"
if echo "$COMBINED" | grep -q "tail -f /var/log/wordpress.log"; then
  pass "Sidecar executes 'tail -f /var/log/wordpress.log'"
else
  fail "Sidecar command does not tail /var/log/wordpress.log" "Command/args: '$COMBINED'"
fi

# 4. Volume mount /var/log
WP_MOUNT=$(kubectl get deploy "$DEPLOY" -n "$NS" -o jsonpath='{.spec.template.spec.containers[?(@.name=="wordpress")].volumeMounts[?(@.mountPath=="/var/log")].mountPath}' 2>/dev/null || echo "")
SC_MOUNT=$(kubectl get deploy "$DEPLOY" -n "$NS" -o jsonpath='{.spec.template.spec.containers[?(@.name=="sidecar")].volumeMounts[?(@.mountPath=="/var/log")].mountPath}' 2>/dev/null || echo "")

if [[ "$WP_MOUNT" == "/var/log" && "$SC_MOUNT" == "/var/log" ]]; then
  pass "Both containers have /var/log mounted"
else
  fail "Volume mount mismatch at /var/log" "wordpress: '$WP_MOUNT', sidecar: '$SC_MOUNT'"
fi

# 5. Pod running status
READY=$(kubectl get deploy "$DEPLOY" -n "$NS" -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")
if [[ "${READY:-0}" -ge 1 ]]; then
  pass "Deployment has ready replicas (${READY})"
else
  fail "Deployment has no ready replicas"
fi

echo "Summary: $PASSED/$TOTAL tests passed"
[[ $FAILED -eq 0 ]] && exit 0 || exit 1

