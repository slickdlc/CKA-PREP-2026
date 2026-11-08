#!/usr/bin/env bash
# ==============================================================================
# cleanup.sh - Question 11: Gateway-API
# ==============================================================================
set -uo pipefail

echo "🧹 Cleaning up: Question-11 Gateway-API..."

kubectl delete httproute web-route --ignore-not-found=true 2>/dev/null || true
kubectl delete gateway web-gateway --ignore-not-found=true 2>/dev/null || true
kubectl delete ingress web --ignore-not-found=true 2>/dev/null || true
kubectl delete service web-service --ignore-not-found=true 2>/dev/null || true
kubectl delete deployment web-deployment --ignore-not-found=true 2>/dev/null || true
kubectl delete secret web-tls --ignore-not-found=true 2>/dev/null || true

# Remove Gateway API CRDs installed by setup
kubectl delete -f "https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.5.0/standard-install.yaml" --ignore-not-found=true 2>/dev/null || true

rm -f gw.yaml http.yaml ~/gw.yaml ~/http.yaml 2>/dev/null || true

echo "✅ Cleanup complete for Question-11"
exit 0

