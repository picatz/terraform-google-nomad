
#!/bin/bash

# CONSUL CONFIGURATION

# Add the Consul CA PEM
cat > /tmp/consul-ca.pem << EOF
${consul_ca_cert}
EOF
sudo mv /tmp/consul-ca.pem /consul/config/consul-ca.pem

# Add the Consul Server PEM
cat > /tmp/server.pem << EOF
${consul_server_cert}
EOF
sudo mv /tmp/server.pem /consul/config/server.pem

# Add the Consul Server Private Key PEM
cat > /tmp/server-key.pem << EOF
${consul_server_private_key}
EOF
sudo mv /tmp/server-key.pem /consul/config/server-key.pem

# Update the {NUMBER-OF-SERVERS} ad-hoc template var
sed -i -e "s/{NUMBER-OF-SERVERS}/${number_of_servers}/g" /consul/config/agent.hcl

# Update the {GOSSIP-SECRET-KEY} ad-hoc template var
sed -i -e "s/{GOSSIP-KEY}/${consul_gossip_secret_key}/g" /consul/config/agent.hcl

# Update the {PROJECT-NAME} ad-hoc template var
sed -i -e "s/{PROJECT-NAME}/${project}/g" /consul/config/agent.hcl

# Update the {ACLs-ENABLED} ad-hoc template var
sed -i -e "s/{ACLs-ENABLED}/${consul_acls_enabled}/g" /consul/config/agent.hcl

# Update the {ACLs-DEFAULT-POLICY} ad-hoc template var
sed -i -e "s/{ACLs-DEFAULT-POLICY}/${consul_acls_default_policy}/g" /consul/config/agent.hcl

# Set ACL master token if ACLs are enabled
if [ "${consul_acls_enabled}" = "true" ]; then
    sed -i -e "s/{CONSUL-TOKEN}/${consul_master_token}/g" /nomad/config/agent.hcl
    sed -i -e "s/{CONSUL-TOKEN}/${consul_master_token}/g" /consul/config/agent.hcl
else
    sed -i -e "s/{CONSUL-TOKEN}//g" /nomad/config/agent.hcl
    sed -i -e "s/{CONSUL-TOKEN}//g" /consul/config/agent.hcl
fi

# Update the {PRIVATE-IPV4} ad-hoc template var
IP=$(curl -H "Metadata-Flavor: Google" http://metadata/computeMetadata/v1/instance/network-interfaces/0/ip)
sed -i -e "s/{PRIVATE-IPV4}/$${IP}/g" /consul/config/agent.hcl

# Enable and start Consul
systemctl enable consul
systemctl start consul

# NOMAD CONFIGURATION

# Add the Nomad CA PEM
cat > /tmp/nomad-ca.pem << EOF
${nomad_ca_cert}
EOF
sudo mv /tmp/nomad-ca.pem /nomad/config/nomad-ca.pem

# Add the Nomad Server PEM
cat > /tmp/server.pem << EOF
${nomad_server_cert}
EOF
sudo mv /tmp/server.pem /nomad/config/server.pem

# Add the Nomad Server Private Key PEM
cat > /tmp/server-key.pem << EOF
${nomad_server_private_key}
EOF
sudo mv /tmp/server-key.pem /nomad/config/server-key.pem

# Update the {NUMBER-OF-SERVERS} ad-hoc template var
sed -i -e "s/{NUMBER-OF-SERVERS}/${number_of_servers}/g" /nomad/config/agent.hcl

# Update the {GOSSIP-SECRET-KEY} ad-hoc template var
sed -i -e "s/{GOSSIP-KEY}/${nomad_gossip_secret_key}/g" /nomad/config/agent.hcl

# Update the {PROJECT-NAME} ad-hoc template var
sed -i -e "s/{PROJECT-NAME}/${project}/g" /nomad/config/agent.hcl

# Update the {ACLs-ENABLED} ad-hoc template var
sed -i -e "s/{ACLs-ENABLED}/${nomad_acls_enabled}/g" /nomad/config/agent.hcl

# Update the {PRIVATE-IPV4} ad-hoc template var
IP=$(curl -H "Metadata-Flavor: Google" http://metadata/computeMetadata/v1/instance/network-interfaces/0/ip)
sed -i -e "s/{PRIVATE-IPV4}/$${IP}/g" /nomad/config/agent.hcl

# Enable and start Nomad
systemctl enable nomad
systemctl start nomad

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
sed -i -e "s/{VAULT-ADDR}/${vault_address}/g" /nomad/config/agent.hcl

# Update the {VAULT-TOKEN} ad-hoc template var
sed -i -e "s,{VAULT-TOKEN},${vault_token},g" /nomad/config/agent.hcl

# Update the {VAULT-ALLOW-UNAUTHENTICATED} ad-hoc template var
sed -i -e "s/{VAULT-ALLOW-UNAUTHENTICATED}/${vault_allow_unauthenticated}/g" /nomad/config/agent.hcl
