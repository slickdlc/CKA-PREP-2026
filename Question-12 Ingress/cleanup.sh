#!/usr/bin/env bash
# ==============================================================================
# cleanup.sh - Question 12: Ingress
# ==============================================================================
set -uo pipefail

echo "🧹 Cleaning up: Question-12 Ingress..."

kubectl delete namespace echo-sound --ignore-not-found=true --timeout=30s || true
rm -f ingress.yaml ~/ingress.yaml 2>/dev/null || true

echo "✅ Cleanup complete for Question-12"
exit 0

