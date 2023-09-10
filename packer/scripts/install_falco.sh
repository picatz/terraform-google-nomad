#!/bin/bash

set -ex

# https://falco.org/docs/getting-started/falco-linux-quickstart/#install-falco
curl -fsSL https://falco.org/repo/falcosecurity-packages.asc | sudo gpg --dearmor -o /usr/share/keyrings/falco-archive-keyring.gpg
sudo bash -c 'cat << EOF > /etc/apt/sources.list.d/falcosecurity.list
    deb [signed-by=/usr/share/keyrings/falco-archive-keyring.gpg] https://download.falco.org/packages/deb stable main
EOF'

sudo apt-get update -y

sudo apt-get -y install linux-headers-$(uname -r)
sudo apt-get install -y falco