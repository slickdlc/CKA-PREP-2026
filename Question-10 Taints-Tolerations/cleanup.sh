#!/usr/bin/env bash
# ==============================================================================
# cleanup.sh - Question 10: Taints-Tolerations
# ==============================================================================
set -uo pipefail

echo "🧹 Cleaning up: Question-10 Taints-Tolerations..."

# Delete test pods
kubectl delete pod nginx nginx-fail -n default --ignore-not-found=true --timeout=30s 2>/dev/null || true

# Remove taint from node01 or any tainted node
kubectl taint node node01 PERMISSION:NoSchedule- 2>/dev/null || true

# Safe fallback across all nodes
for n in $(kubectl get nodes -o jsonpath='{.items[*].metadata.name}' 2>/dev/null || echo ""); do
  kubectl taint node "$n" PERMISSION:NoSchedule- 2>/dev/null || true
done

rm -f pod.yaml podfailure.yaml ~/pod.yaml ~/podfailure.yaml 2>/dev/null || true

echo "✅ Cleanup complete for Question-10"
exit 0

