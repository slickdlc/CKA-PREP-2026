#!/usr/bin/env bash
# ==============================================================================
# cleanup.sh - Question 9: Cri-Dockerd
# ==============================================================================
set -uo pipefail

echo "🧹 Cleaning up: Question-9 Cri-Dockerd..."

# Stop and disable cri-docker if running
sudo systemctl stop cri-docker.service cri-docker.socket 2>/dev/null || true
sudo systemctl disable cri-docker.service cri-docker.socket 2>/dev/null || true

# Remove package and config
sudo dpkg -r cri-dockerd 2>/dev/null || true
sudo rm -f /etc/sysctl.d/kube.conf /root/cri-dockerd.deb 2>/dev/null || true

echo "✅ Cleanup complete for Question-9"
exit 0

