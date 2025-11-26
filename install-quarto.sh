#!/bin/bash
set -e

echo "📦 Installing Quarto..."

# Set default version if not set
QUARTO_VERSION=${QUARTO_VERSION:-1.4.550}

# Download and extract
wget -q "https://github.com/quarto-dev/quarto-cli/releases/download/v${QUARTO_VERSION}/quarto-${QUARTO_VERSION}-linux-amd64.tar.gz" -O quarto.tar.gz
tar -xzf quarto.tar.gz

# Rename the extracted folder for clarity
mv "quarto-${QUARTO_VERSION}" quarto-cli

# Add to PATH
export PATH=$(pwd)/quarto-cli/bin:$PATH

# Confirm install
echo "✅ Quarto version:"
quarto --version

