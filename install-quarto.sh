#!/bin/bash
set -e

echo "📦 Installing Quarto..."

QUARTO_VERSION=${QUARTO_VERSION:-1.4.550}
wget -q "https://github.com/quarto-dev/quarto-cli/releases/download/v${QUARTO_VERSION}/quarto-${QUARTO_VERSION}-linux-amd64.tar.gz" -O quarto.tar.gz
tar -xzf quarto.tar.gz
mv "quarto-${QUARTO_VERSION}" quarto-cli
export PATH="$(pwd)/quarto-cli/bin:$PATH"

# Confirm Quarto installed
quarto --version

echo "📦 Installing R..."

# Install R (minimal)
apt-get update
apt-get install -y --no-install-recommends r-base

# Confirm R installed
Rscript --version

echo "🚀 Rendering site..."
quarto render

