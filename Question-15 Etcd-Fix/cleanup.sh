#!/usr/bin/env bash
# ==============================================================================
# cleanup.sh - Question 15: Etcd-Fix
# ==============================================================================
set -uo pipefail

echo "🧹 Cleaning up: Question-15 Etcd-Fix..."

# Restore original apiserver manifest from backup if present
if [[ -f /root/kube-apiserver.yaml.bak ]]; then
  sudo cp /root/kube-apiserver.yaml.bak /etc/kubernetes/manifests/kube-apiserver.yaml
  sudo rm -f /root/kube-apiserver.yaml.bak
  echo "Restored /etc/kubernetes/manifests/kube-apiserver.yaml from backup."
elif [[ -f /etc/kubernetes/manifests/kube-apiserver.yaml ]]; then
  # Revert port 2380 back to client port 2379
  sudo sed -i 's/:2380/:2379/g' /etc/kubernetes/manifests/kube-apiserver.yaml
  echo "Reverted etcd port in /etc/kubernetes/manifests/kube-apiserver.yaml to 2379."
fi

echo "✅ Cleanup complete for Question-15"
exit 0

