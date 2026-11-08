#!/usr/bin/env bash
# ==============================================================================
# cleanup.sh - Question 17: TLS-Config
# ==============================================================================
set -uo pipefail

echo "🧹 Cleaning up: Question-17 TLS-Config..."

kubectl delete namespace nginx-static --ignore-not-found=true --timeout=30s || true
sudo sed -i '/ckaquestion\.k8s\.local/d' /etc/hosts 2>/dev/null || true
rm -f tls.key tls.crt ~/tls.key ~/tls.crt 2>/dev/null || true

echo "✅ Cleanup complete for Question-17"
exit 0

