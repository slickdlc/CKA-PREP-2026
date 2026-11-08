#!/usr/bin/env bash
# ==============================================================================
# cleanup.sh - Question 5: HPA
# ==============================================================================
set -uo pipefail

echo "🧹 Cleaning up: Question-5 HPA..."

kubectl delete hpa apache-server -n autoscale --ignore-not-found=true 2>/dev/null || true
kubectl delete namespace autoscale --ignore-not-found=true --timeout=30s || true
rm -f hpa.yaml ~/hpa.yaml 2>/dev/null || true

echo "✅ Cleanup complete for Question-5"
exit 0

