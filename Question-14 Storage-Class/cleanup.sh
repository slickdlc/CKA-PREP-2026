#!/usr/bin/env bash
# ==============================================================================
# cleanup.sh - Question 14: Storage-Class
# ==============================================================================
set -uo pipefail

echo "🧹 Cleaning up: Question-14 Storage-Class..."

# Remove student storageclass
kubectl delete storageclass local-storage --ignore-not-found=true 2>/dev/null || true

# Restore local-path as default if it exists
if kubectl get storageclass local-path >/dev/null 2>&1; then
  kubectl patch storageclass local-path -p '{"metadata":{"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}' 2>/dev/null || true
fi

rm -f sc.yaml ~/sc.yaml 2>/dev/null || true

echo "✅ Cleanup complete for Question-14"
exit 0

