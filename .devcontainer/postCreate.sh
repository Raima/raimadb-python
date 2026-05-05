#!/usr/bin/env bash
set -euo pipefail

echo "[devcontainer] Fixing expired Yarn GPG key..."
sudo rm -f /etc/apt/sources.list.d/yarn.list || true

echo "[devcontainer] Installing native build tools..."
sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    build-essential gdb cmake pkg-config
sudo apt-get clean
sudo rm -rf /var/lib/apt/lists/*

if [ -d .venv ]; then
  echo "[devcontainer] Removing existing .venv (created outside Docker or from previous host Python)..."
  rm -rf .venv
fi

echo "[devcontainer] Creating fresh .venv using the container's Python..."
python -m venv .venv

echo "[devcontainer] Upgrading pip + installing Cython into .venv..."
.venv/bin/pip install --upgrade pip setuptools wheel
.venv/bin/pip install --upgrade Cython

if [[ ! -d /opt/Raima ]]; then
  echo "[devcontainer] WARNING: /opt/Raima not mounted. Skipping editable install."
  exit 0
fi

if ! ls /opt/Raima/rdm_* >/dev/null 2>&1; then
  echo "[devcontainer] WARNING: No RaimaDB rdm_* files found. Skipping editable install."
  exit 0
fi

echo "[devcontainer] Installing project (editable + dev extras) into .venv..."
.venv/bin/pip install -e ".[dev]"

echo "[devcontainer] Done. .venv is now fresh and matches the Docker environment."