#!/usr/bin/env bash
# ==============================================================================
# cleanup.sh - Question 13: Network-Policy
# ==============================================================================
set -uo pipefail

echo "🧹 Cleaning up: Question-13 Network-Policy..."

kubectl delete namespace frontend backend --ignore-not-found=true --timeout=30s || true
rm -rf /root/network-policies ~/network-policies 2>/dev/null || true

echo "✅ Cleanup complete for Question-13"
exit 0

