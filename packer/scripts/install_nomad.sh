#!/bin/bash

set -ex

# Latest version of Nomad
NOMAD_VERSION=1.2.3

# Download Latest Version of Nomad
mkdir -p /tmp/download-nomad
cd /tmp/download-nomad
curl "https://releases.hashicorp.com/nomad/${NOMAD_VERSION}/nomad_${NOMAD_VERSION}_linux_amd64.zip" -o nomad.zip
unzip nomad.zip
sudo chown root:root nomad
sudo mv nomad /bin
cd /tmp
rm -rf /tmp/download-nomad
nomad version

# Setup Systemd Service
sudo touch /etc/systemd/system/nomad.service
sudo mv /tmp/nomad.service /etc/systemd/system/nomad.service
sudo systemctl daemon-reload

# Setup Config and Data Directory
sudo mkdir -p /nomad/data && sudo mkdir -p /nomad/config
sudo mv /tmp/nomad-agent.hcl /nomad/config/agent.hcl
sudo chown --recursive root:root /nomad