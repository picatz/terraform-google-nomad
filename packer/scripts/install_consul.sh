#!/bin/bash

set -ex

# Download Latest Version of Consul 
# https://developer.hashicorp.com/consul/docs/install
sudo apt-get install -y consul

# Move /tmp/consul-agent.hcl to /etc/consul.d/consul.hcl
sudo mv /tmp/consul-agent.hcl /etc/consul.d/consul.hcl