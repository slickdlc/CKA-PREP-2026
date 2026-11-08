#!/usr/bin/env bash
# ==============================================================================
# cleanup.sh - Question 4: Resource-Allocation
# ==============================================================================
set -uo pipefail

echo "🧹 Cleaning up: Question-4 Resource-Allocation..."

kubectl delete deployment wordpress -n default --ignore-not-found=true --timeout=30s || true

echo "✅ Cleanup complete for Question-4"
exit 0

