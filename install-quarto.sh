#!/bin/bash

set -e

echo "Installing Quarto version ${QUARTO_VERSION}..."

wget -q https://quarto.org/download/latest/quarto-linux-amd64.tar.gz
tar -xzf quarto-linux-amd64.tar.gz
mv quarto-* /opt/quarto
ln -s /opt/quarto/bin/quarto /usr/local/bin/quarto

echo "Quarto installed:"
quarto --version
