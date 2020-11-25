#!/bin/bash

set -ex

# Latest version of Consul
CONSUL_VERSION=1.9.0

# Download Latest Version of Consul
mkdir -p /tmp/download-consul
cd /tmp/download-consul
curl "https://releases.hashicorp.com/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_linux_amd64.zip" -o consul.zip
unzip consul.zip
sudo chown root:root consul
sudo mv consul /bin
cd /tmp
rm -rf /tmp/download-consul
consul version

# Create user
sudo useradd --system --home /consul --shell /bin/false consul

# Setup Systemd Service
sudo touch /etc/systemd/system/consul.service
sudo mv /tmp/consul.service /etc/systemd/system/consul.service
sudo systemctl daemon-reload

# Setup Config and Data Directory
sudo mkdir -p /consul/data && sudo mkdir -p /consul/config
sudo mv /tmp/consul-agent.hcl /consul/config/agent.hcl
sudo chown --recursive consul:consul /consul
