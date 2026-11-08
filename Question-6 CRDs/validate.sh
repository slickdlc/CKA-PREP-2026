#!/usr/bin/env bash
# ==============================================================================
# validate.sh - Question 6: CRDs
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

echo "=== Validating: Question-6 CRDs ==="

# 1. /root/resources.yaml exists and contains cert-manager CRDs
RESOURCES_FILE="/root/resources.yaml"
if [[ -f "$RESOURCES_FILE" && -s "$RESOURCES_FILE" ]]; then
  pass "File '$RESOURCES_FILE' exists and is non-empty"
  if grep -qi "cert-manager" "$RESOURCES_FILE"; then
    pass "File '$RESOURCES_FILE' contains cert-manager CRD listings"
  else
    fail "File '$RESOURCES_FILE' does not contain cert-manager resources"
  fi
else
  fail "File '$RESOURCES_FILE' missing or empty"
fi

# 2. /root/subject.yaml exists and contains certificate subject explain documentation
SUBJECT_FILE="/root/subject.yaml"
if [[ -f "$SUBJECT_FILE" && -s "$SUBJECT_FILE" ]]; then
  pass "File '$SUBJECT_FILE' exists and is non-empty"
  if grep -qi "subject" "$SUBJECT_FILE" && (grep -qi "FIELD" "$SUBJECT_FILE" || grep -qi "organizations" "$SUBJECT_FILE" || grep -qi "countries" "$SUBJECT_FILE"); then
    pass "File '$SUBJECT_FILE' contains certificate subject documentation"
  else
    fail "File '$SUBJECT_FILE' does not match kubectl explain output for certificate.spec.subject"
  fi
else
  fail "File '$SUBJECT_FILE' missing or empty"
fi

echo "Summary: $PASSED/$TOTAL tests passed"
[[ $FAILED -eq 0 ]] && exit 0 || exit 1

