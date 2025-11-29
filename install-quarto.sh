#!/bin/bash
#!/bin/bash
set -e

echo "Installing Quarto..."
curl -LO https://quarto.org/download/latest/quarto-linux-amd64.deb
dpkg -i quarto-linux-amd64.deb

