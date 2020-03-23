#!/bin/bash

set -ex

mkdir -p /tmp/build
cd /tmp/build
curl https://releases.hashicorp.com/nomad/0.10.4/nomad_0.10.4_linux_amd64.zip -o nomad.zip
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
# sudo systemctl enable nomad

sudo mkdir -p /nomad/data && sudo mkdir -p /nomad/config

sudo mv /tmp/agent.hcl /nomad/config/agent.hcl
sudo chown -R nomad:nomad /nomad
# sudo systemctl start nomad
# sudo systemctl status nomad

if [ -f /tmp/nomad-ca.pem ]; then
    sudo mv /tmp/nomad-ca.pem  /nomad/config/nomad-ca.pem
fi

if [ -f /tmp/server.pem ]; then
    sudo mv /tmp/server.pem /nomad/config/server.pem
fi

if [ -f /tmp/server-key.pem ]; then
    sudo mv /tmp/server-key.pem /nomad/config/server-key.pem
fi

if [ -f /tmp/client.pem ]; then
    sudo mv /tmp/client.pem /nomad/config/client.pem
fi

if [ -f /tmp/client-key.pem ]; then
    sudo mv /tmp/client-key.pem /nomad/config/client-key.pem
fi

if [ -f /tmp/nomad.env]; then
    sudo mv /tmp/nomad.env /nomad/config/nomad.env
fi

sudo chown -R nomad:nomad /nomad
