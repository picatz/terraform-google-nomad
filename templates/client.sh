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

# Start and enable Nomad
systemctl start nomad
systemctl enable nomad

# Block access to the metadata endpoint in four easy steps
# https://github.com/picatz/terraform-google-nomad/issues/19
#
# 1. Create NOAMD-ADMIN chain
sudo iptables --new NOMAD-ADMIN
# 2. Add default rule (this is appended by Nomad by default to the end of the chain as well... maye not needed?)
sudo iptables --append NOMAD-ADMIN --destination 172.26.64.0/20  --jump ACCEPT
# 3. Allow access to metadata endpoint for DNS resolution (UDP only)
sudo iptables --append NOMAD-ADMIN --destination 169.254.169.254/32 --protocol udp --dport 53 --jump ACCEPT
# 4. Block access to metadata endpoint
sudo iptables --append NOMAD-ADMIN --destination 169.254.169.254/32 --jump DROP

# VAULT CONFIGURATION

# Add the Vault CA PEM
cat > /tmp/vault-ca.pem << EOF
${vault_ca_cert}
EOF
sudo mv /tmp/vault-ca.pem /vault/config/vault-ca.pem

# Add the Vault Client PEM
cat > /tmp/client.pem << EOF
${vault_client_cert}
EOF
sudo mv /tmp/client.pem /vault/config/client.pem

# Add the Vault Client Private Key PEM
cat > /tmp/client-key.pem << EOF
${vault_client_private_key}
EOF
sudo mv /tmp/client-key.pem /vault/config/client-key.pem

# Update the {VAULT-ENABLED} ad-hoc template var
sed -i -e "s/{VAULT-ENABLED}/${vault_enabled}/g" /nomad/config/agent.hcl

# Update the {VAULT-ADDR} ad-hoc template var
sed -i -e "s,{VAULT-ADDR},${vault_address},g" /nomad/config/agent.hcl

# Update the {VAULT-ALLOW-UNAUTHENTICATED} ad-hoc template var
sed -i -e "s/{VAULT-ALLOW-UNAUTHENTICATED}/${vault_allow_unauthenticated}/g" /nomad/config/agent.hcl
