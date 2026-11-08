#!/usr/bin/env bash
# ==============================================================================
# cleanup.sh - Question 3: Sidecar
# ==============================================================================
set -uo pipefail

echo "🧹 Cleaning up: Question-3 Sidecar..."

kubectl delete deployment wordpress -n default --ignore-not-found=true --timeout=30s || true
kubectl delete service wordpress -n default --ignore-not-found=true --timeout=30s || true

echo "✅ Cleanup complete for Question-3"
exit 0

