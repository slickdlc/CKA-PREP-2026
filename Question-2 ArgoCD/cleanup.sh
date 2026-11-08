#!/usr/bin/env bash
# ==============================================================================
# cleanup.sh - Question 2: ArgoCD
# ==============================================================================
set -uo pipefail

echo "🧹 Cleaning up: Question-2 ArgoCD..."

kubectl delete namespace argocd --ignore-not-found=true --timeout=30s || true
helm repo remove argocd 2>/dev/null || true
rm -f /root/argo-helm.yaml ~/argo-helm.yaml argo-helm.yaml 2>/dev/null || true

echo "✅ Cleanup complete for Question-2"
exit 0

