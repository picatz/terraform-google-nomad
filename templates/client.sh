#!/bin/bash

# CONSUL CONFIGURATION

# Add the Consul CA PEM
cat > /tmp/consul-ca.pem << EOF
${consul_ca_cert}
EOF
sudo mv /tmp/consul-ca.pem /consul/config/consul-ca.pem

# Add the Consul Client PEM
cat > /tmp/client.pem << EOF
${consul_client_cert}
EOF
sudo mv /tmp/client.pem /consul/config/client.pem

# Add the Consul Client Private Key PEM
cat > /tmp/client-key.pem << EOF
${consul_client_private_key}
EOF
sudo mv /tmp/client-key.pem /consul/config/client-key.pem

# Update the {ACLs-ENABLED} ad-hoc template var
sed -i -e "s/{ACLs-ENABLED}/${consul_acls_enabled}/g" /consul/config/agent.hcl

# Update the {ACLs-DEFAULT-POLICY} ad-hoc template var
sed -i -e "s/{ACLs-DEFAULT-POLICY}/${consul_acls_default_policy}/g" /consul/config/agent.hcl

# Update the {ACLs-ENABLED} ad-hoc template var
sed -i -e "s/{CONSUL-TOKEN}/${consul_master_token}/g" /consul/config/agent.hcl

# Set ACL master token if ACLs are enabled
if [ "${consul_acls_enabled}" = "true" ]; then
    sed -i -e "s/{CONSUL-TOKEN}/${consul_master_token}/g" /nomad/config/agent.hcl
    sed -i -e "s/{CONSUL-TOKEN}/${consul_master_token}/g" /consul/config/agent.hcl
else
    sed -i -e "s/{CONSUL-TOKEN}//g" /nomad/config/agent.hcl
    sed -i -e "s/{CONSUL-TOKEN}//g" /consul/config/agent.hcl
fi

# Update the {PROJECT-NAME} ad-hoc template var
sed -i -e "s/{PROJECT-NAME}/${project}/g" /consul/config/agent.hcl

# Update the {PRIVATE-IPV4} ad-hoc template var
IP=$(curl -H "Metadata-Flavor: Google" http://metadata/computeMetadata/v1/instance/network-interfaces/0/ip)
sed -i -e "s/{PRIVATE-IPV4}/$${IP}/g" /consul/config/agent.hcl

# Update the {GOSSIP-SECRET-KEY} ad-hoc template var
sed -i -e "s/{GOSSIP-KEY}/${consul_gossip_secret_key}/g" /consul/config/agent.hcl

# Start and enable Consul
systemctl start consul
systemctl enable consul

# NOMAD CONFIGURATION

# Add the Nomad CA PEM
cat > /tmp/nomad-ca.pem << EOF
${nomad_ca_cert}
EOF
sudo mv /tmp/nomad-ca.pem /nomad/config/nomad-ca.pem

# Add the Nomad Client PEM
cat > /tmp/client.pem << EOF
${nomad_client_cert}
EOF
sudo mv /tmp/client.pem /nomad/config/client.pem

# Add the Nomad Client Private Key PEM
cat > /tmp/client-key.pem << EOF
${nomad_client_private_key}
EOF
sudo mv /tmp/client-key.pem /nomad/config/client-key.pem

# Update the {ACLs-ENABLED} ad-hoc template var
sed -i -e "s/{ACLs-ENABLED}/${nomad_acls_enabled}/g" /nomad/config/agent.hcl

# Update the {PROJECT-NAME} ad-hoc template var
sed -i -e "s/{PROJECT-NAME}/${project}/g" /nomad/config/agent.hcl

# Configure the Docker Daemon
cat > /tmp/daemon.json << EOF
${docker_config}
EOF
sudo mv /tmp/daemon.json /etc/docker/daemon.json

# Restart docker to apply changes
systemctl restart docker

# install GCS FUSE plugin
# export GCSFUSE_REPO=gcsfuse-`lsb_release -c -s`
# echo "deb http://packages.cloud.google.com/apt $GCSFUSE_REPO main" | sudo tee /etc/apt/sources.list.d/gcsfuse.list
# curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
# sudo apt-get update -y
# sudo apt-get install gcsfuse -y
# # and configure the mount path
# sudo mkdir /gcs
# sudo gcsfuse ${bucket_name} /gcs
cat > /tmp/gcsfuse.env << EOF
GCSFUSE_BUCKET=${bucket_name}
EOF
sudo mv /tmp/gcsfuse.env /etc/gcsfuse.env
systemctl start gcsfuse
systemctl enable gcsfuse

# Start and enable Nomad
systemctl start nomad
systemctl enable nomad
