#!/usr/bin/env bash
# ==============================================================================
# cleanup.sh - Question 6: CRDs
# ==============================================================================
set -uo pipefail

echo "🧹 Cleaning up: Question-6 CRDs..."

kubectl delete namespace cert-manager --ignore-not-found=true --timeout=30s || true
kubectl delete -f https://github.com/cert-manager/cert-manager/releases/download/v1.14.0/cert-manager.crds.yaml --ignore-not-found=true 2>/dev/null || true
rm -f /root/resources.yaml /root/subject.yaml ~/resources.yaml ~/subject.yaml 2>/dev/null || true

echo "✅ Cleanup complete for Question-6"
exit 0

