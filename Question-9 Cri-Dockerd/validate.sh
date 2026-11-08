#!/usr/bin/env bash
# ==============================================================================
# validate.sh - Question 9: Cri-Dockerd
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

echo "=== Validating: Question-9 Cri-Dockerd ==="

# 1. cri-docker service running
if systemctl is-active --quiet cri-docker 2>/dev/null; then
  pass "cri-docker service is active and running"
else
  fail "cri-docker service is not active"
fi

# 2. Check sysctl live values
check_sysctl() {
  local param="$1"
  local expected="$2"
  local val
  val=$(sysctl -n "$param" 2>/dev/null || echo "")
  if [[ "$val" == "$expected" ]]; then
    pass "sysctl $param = $expected"
  else
    fail "sysctl $param expected '$expected', got '$val'"
  fi
}

check_sysctl "net.bridge.bridge-nf-call-iptables" "1"
check_sysctl "net.ipv6.conf.all.forwarding" "1"
check_sysctl "net.ipv4.ip_forward" "1"
check_sysctl "net.netfilter.nf_conntrack_max" "131072"

# 3. Persistent sysctl configuration file
if grep -rs "net.bridge.bridge-nf-call-iptables" /etc/sysctl.d/ /etc/sysctl.conf 2>/dev/null | grep -q "1"; then
  pass "Persistent sysctl configuration found in /etc/sysctl.d/ or /etc/sysctl.conf"
else
  fail "No persistent configuration found in /etc/sysctl.d/"
fi

echo "Summary: $PASSED/$TOTAL tests passed"
[[ $FAILED -eq 0 ]] && exit 0 || exit 1

