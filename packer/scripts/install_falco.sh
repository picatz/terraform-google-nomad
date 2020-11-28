#!/bin/bash

set -ex

curl -s https://falco.org/repo/falcosecurity-3672BA8F.asc | sudo apt-key add -
echo "deb https://dl.bintray.com/falcosecurity/deb stable main" | sudo tee -a /etc/apt/sources.list.d/falcosecurity.list
sudo apt-get update -y
sudo apt-get -y install linux-headers-$(uname -r)
sudo apt-get install -y falco