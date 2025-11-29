#!/bin/bash
set -e

# Quarto version (pin if needed)
QUARTO_VERSION="1.4.550"

# Download Quarto CLI (tar.gz version - does NOT require sudo)
curl -LO https://github.com/quarto-dev/quarto-cli/releases/download/v${QUARTO_VERSION}/quarto-${QUARTO_VERSION}-linux-amd64.tar.gz

# Extract to a local directory
tar -xvzf quarto-${QUARTO_VERSION}-linux-amd64.tar.gz

# Add Quarto to PATH (this lasts for the current build)
export PATH=$PWD/quarto-${QUARTO_VERSION}/bin:$PATH

# Check version to confirm install
quarto --version
