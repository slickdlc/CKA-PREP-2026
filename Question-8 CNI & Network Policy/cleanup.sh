#!/usr/bin/env bash
# ==============================================================================
# cleanup.sh - Question 8: CNI & Network Policy
# ==============================================================================
set -uo pipefail

echo "🧹 Cleaning up: Question-8 CNI & Network Policy..."

# Remove manifests applied during the lab (Calico or Flannel)
kubectl delete -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.2/manifests/tigera-operator.yaml --ignore-not-found=true 2>/dev/null || true
kubectl delete -f https://github.com/flannel-io/flannel/releases/download/v0.26.1/kube-flannel.yml --ignore-not-found=true 2>/dev/null || true

echo "✅ Cleanup complete for Question-8"
exit 0

