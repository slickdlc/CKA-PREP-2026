#!/usr/bin/env bash
# ==============================================================================
# cleanup.sh - Question 1: MariaDB-Persistent volume
# ==============================================================================
set -uo pipefail

echo "🧹 Cleaning up: Question-1 MariaDB-Persistent volume..."

kubectl delete namespace mariadb --ignore-not-found=true --timeout=30s || true
kubectl delete pv mariadb-pv --ignore-not-found=true --timeout=30s || true

rm -f ~/mariadb-deploy.yaml ~/pvc.yaml pvc.yaml 2>/dev/null || true
sudo rm -rf /mnt/data/mariadb 2>/dev/null || true

echo "✅ Cleanup complete for Question-1"
exit 0

