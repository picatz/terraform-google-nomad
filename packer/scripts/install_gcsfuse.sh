#!/bin/bash

set -ex

# install gcfuse
export GCSFUSE_REPO=gcsfuse-`lsb_release -c -s`
echo "deb http://packages.cloud.google.com/apt $GCSFUSE_REPO main" | sudo tee /etc/apt/sources.list.d/gcsfuse.list
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
sudo apt-get update -y
sudo apt-get install gcsfuse -y

## Shared GCS Bucket on /gcs

# setup systemd service
sudo touch /etc/systemd/system/gcsfuse-shared.service
sudo mv /tmp/gcsfuse-shared.service /etc/systemd/system/gcsfuse-shared.service
sudo systemctl daemon-reload

# and create the eventual mount path
sudo mkdir /gcs

# and create systemd environment file
# which will be populate by terraform dynamically with the bucket name
# environment variable used by gcsfuse
sudo touch /etc/gcsfuse-shared.env

## Prometheus GCS Bucket on /prometheus

# setup systemd service
sudo touch /etc/systemd/system/gcsfuse-prometheus.service
sudo mv /tmp/gcsfuse-prometheus.service /etc/systemd/system/gcsfuse-prometheus.service
sudo systemctl daemon-reload

# and create the eventual mount path
sudo mkdir /prometheus

# and create systemd environment file
# which will be populate by terraform dynamically with the bucket name
# environment variable used by gcsfuse
sudo touch /etc/gcsfuse-prometheus.env

## Grafana GCS Bucket on /grafana

# setup systemd service
sudo touch /etc/systemd/system/gcsfuse-grafana.service
sudo mv /tmp/gcsfuse-grafana.service /etc/systemd/system/gcsfuse-grafana.service
sudo systemctl daemon-reload

# and create the eventual mount path
sudo mkdir /grafana

# and create systemd environment file
# which will be populate by terraform dynamically with the bucket name
# environment variable used by gcsfuse
sudo touch /etc/gcsfuse-grafana.env
