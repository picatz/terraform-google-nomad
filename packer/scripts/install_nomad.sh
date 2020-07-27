#!/bin/bash

set -ex

NOMAD_VERSION=0.12.1

mkdir -p /tmp/build
cd /tmp/build
curl "https://releases.hashicorp.com/nomad/${NOMAD_VERSION}/nomad_${NOMAD_VERSION}_linux_amd64.zip" -o nomad.zip
unzip nomad.zip
sudo mv nomad /bin
cd /tmp
rm -rf /tmp/build
nomad version

sudo adduser --disabled-password --gecos "" nomad
sudo usermod -aG nomad nomad
# put nomad user is docker group too
if sudo grep -q "docker" /etc/group; then
    sudo usermod -aG docker nomad
fi

sudo touch /etc/systemd/system/nomad.service
sudo mv /tmp/nomad.service /etc/systemd/system/nomad.service
sudo systemctl daemon-reload

sudo mkdir -p /nomad/data && sudo mkdir -p /nomad/config

sudo mv /tmp/agent.hcl /nomad/config/agent.hcl
sudo chown -R nomad:nomad /nomad
