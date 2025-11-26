#!/bin/bash
set -e

echo "📦 Installing Quarto..."

# Set default version if not provided
QUARTO_VERSION=${QUARTO_VERSION:-1.4.550}

# Download and extract
wget -q "https://github.com/quarto-dev/quarto-cli/releases/download/v${QUARTO_VERSION}/quarto-${QUARTO_VERSION}-linux-amd64.tar.gz" -O quarto.tar.gz
tar -xzf quarto.tar.gz
mv "quarto-${QUARTO_VERSION}" quarto-cli

# Add to PATH for this script only
export PATH="$(pwd)/quarto-cli/bin:$PATH"

# Confirm version
quarto --version

# ✅ Run render here, with correct PATH
quarto render

