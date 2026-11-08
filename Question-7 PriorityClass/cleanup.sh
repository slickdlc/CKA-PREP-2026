#!/usr/bin/env bash
# ==============================================================================
# cleanup.sh - Question 7: PriorityClass
# ==============================================================================
set -uo pipefail

echo "🧹 Cleaning up: Question-7 PriorityClass..."

kubectl delete namespace priority --ignore-not-found=true --timeout=30s || true
kubectl delete priorityclass user-critical high-priority --ignore-not-found=true 2>/dev/null || true

echo "✅ Cleanup complete for Question-7"
exit 0

