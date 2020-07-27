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

# If gVsior is enabled, then install it
if [ "${gvisor_enabled}" = "true" ]; then
    curl -fsSL https://gvisor.dev/archive.key | sudo apt-key add -
    add-apt-repository "deb https://storage.googleapis.com/gvisor/releases ${gvisor_release} main"
    apt-get update && sudo apt-get install -y runsc
    runsc install
fi

# Configure default docker runtime
cat /etc/docker/daemon.json  | jq '{"default-runtime": "${docker_default_runtime}"} + .' > /tmp/daemon.json
cat /tmp/daemon.json > /etc/docker/daemon.json
rm /tmp/daemon.json

# Optionally enable no-new-privileges
if [ "${docker_no_new_privileges}" = "true" ]; then
    cat /etc/docker/daemon.json  | jq '. + {"no-new-privileges": true}' > /tmp/daemon.json
    cat /tmp/daemon.json > /etc/docker/daemon.json
    rm /tmp/daemon.json
fi

# Optionally disable icc
if [ "${docker_icc_enabled}" = "false" ]; then
    cat /etc/docker/daemon.json  | jq '. + {"icc": false}' > /tmp/daemon.json
    cat /tmp/daemon.json > /etc/docker/daemon.json
    rm /tmp/daemon.json
fi

# Restart docker to apply changes
systemctl restart docker

# Start and enable Nomad
systemctl start nomad
systemctl enable nomad
