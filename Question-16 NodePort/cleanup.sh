#!/usr/bin/env bash
# ==============================================================================
# cleanup.sh - Question 16: NodePort
# ==============================================================================
set -uo pipefail

echo "🧹 Cleaning up: Question-16 NodePort..."

kubectl delete namespace relative --ignore-not-found=true --timeout=30s || true

echo "✅ Cleanup complete for Question-16"
exit 0

