SERVERS ?= 3
CLIENTS ?= 5
CLIENT_MACHINE_TYPE ?= n1-standard-2
SERVER_MACHINE_TYPE ?= n1-standard-1
DNS_ENABLED ?= false
PUBLIC_DOMAIN ?= ""
GRAFANA_LOAD_BALANCER_ENABLED ?= false
GRAFANA_PUBLIC_DOMAIN ?= ""
PROMSCALE_ENABLED ?= false
SSH_BASTION_ENABLED ?= false

.PHONY: help
help: ## Print this help menu
help:
	@echo HashiCorp Nomad on GCP
	@echo
	@echo Required environment variables:
	@echo "* GOOGLE_PROJECT (${GOOGLE_PROJECT})"
	@echo "* GOOGLE_APPLICATION_CREDENTIALS (${GOOGLE_APPLICATION_CREDENTIALS})"
	@echo
	@echo 'Usage: make <target>'
	@echo
	@echo 'Targets:'
	@egrep '^(.+)\:\ ##\ (.+)' $(MAKEFILE_LIST) | column -t -c 2 -s ':#'

.PHONY: packer/init
packer/init: ## Initializes the Packer config
	@cd packer && packer init template.pkr.hcl

.PHONY: packer/validate
packer/validate: ## Validates the Packer config
	@cd packer && packer validate template.pkr.hcl

.PHONY: packer/build
packer/build: ## Forces a build with Packer
	@cd packer && time packer build \
		-force \
		-timestamp-ui \
		template.pkr.hcl

.PHONY: terraform/validate
terraform/validate: ## Validates the Terraform config
	@terraform validate

.PHONY: terraform/plan
terraform/plan: ## Runs the Terraform plan command
	@terraform plan \
		-var="project=${GOOGLE_PROJECT}" \
		-var="bastion_enabled=$(SSH_BASTION_ENABLED)" \
		-var="server_instances=$(SERVERS)" \
		-var="client_instances=$(CLIENTS)" \
		-var="client_machine_type=$(CLIENT_MACHINE_TYPE)" \
		-var="server_machine_type=$(SERVER_MACHINE_TYPE)" \
		-var="grafana_load_balancer_enabled=$(GRAFANA_LOAD_BALANCER_ENABLED)" \
		-var="grafana_dns_managed_zone_dns_name=$(GRAFANA_PUBLIC_DOMAIN)" \
		-var="dns_enabled=$(DNS_ENABLED)" \
		-var="dns_managed_zone_dns_name=$(PUBLIC_DOMAIN)" \
		-var="credentials=${GOOGLE_APPLICATION_CREDENTIALS}"

.PHONY: terraform/wait
terraform/wait: ## Waits for infra to be ready
	@echo "... waiting 30 seconds for all services to be ready before starting proxy ..."
	@sleep 30

.PHONY: terraform/output
terraform/output: ## Gets the Terraform output
	@terraform output -json

.PHONY: terraform/up
terraform/up: terraform/apply terraform/wait ssh/proxy/mtls ## Spins up infrastructure and local proxy

.PHONY: terraform/apply
terraform/apply: ## Runs and auto-apporves the Terraform apply command
	@terraform apply \
		-auto-approve \
		-var="project=${GOOGLE_PROJECT}" \
		-var="bastion_enabled=$(SSH_BASTION_ENABLED)" \
		-var="server_instances=$(SERVERS)" \
		-var="client_instances=$(CLIENTS)" \
		-var="client_machine_type=$(CLIENT_MACHINE_TYPE)" \
		-var="server_machine_type=$(SERVER_MACHINE_TYPE)" \
		-var="grafana_load_balancer_enabled=$(GRAFANA_LOAD_BALANCER_ENABLED)" \
		-var="grafana_dns_managed_zone_dns_name=$(GRAFANA_PUBLIC_DOMAIN)" \
		-var="dns_enabled=$(DNS_ENABLED)" \
		-var="dns_managed_zone_dns_name=$(PUBLIC_DOMAIN)" \
		-var="credentials=${GOOGLE_APPLICATION_CREDENTIALS}"

.PHONY: terraform/shutdown
terraform/shutdown: ## Turns off all VM instances
	@terraform apply \
		-auto-approve \
		-var="project=${GOOGLE_PROJECT}" \
		-var="bastion_enabled=$(SSH_BASTION_ENABLED)" \
		-var="server_instances=0" \
		-var="client_instances=0" \
		-var="client_machine_type=$(CLIENT_MACHINE_TYPE)" \
		-var="server_machine_type=$(SERVER_MACHINE_TYPE)" \
		-var="grafana_load_balancer_enabled=$(GRAFANA_LOAD_BALANCER_ENABLED)" \
		-var="grafana_dns_managed_zone_dns_name=$(GRAFANA_PUBLIC_DOMAIN)" \
		-var="dns_enabled=$(DNS_ENABLED)" \
		-var="dns_managed_zone_dns_name=$(PUBLIC_DOMAIN)" \
		-var="credentials=${GOOGLE_APPLICATION_CREDENTIALS}"

.PHONY: terraform/restart
terraform/restart: terraform/shutdown terraform/apply ## Shuts down all VM instances and restarts them

.PHONY: terraform/destroy
terraform/destroy: ## Runs and auto-apporves the Terraform destroy command
	@terraform destroy \
		-auto-approve \
		-var="project=${GOOGLE_PROJECT}" \
		-var="bastion_enabled=$(SSH_BASTION_ENABLED)" \
		-var="server_instances=$(SERVERS)" \
		-var="client_instances=$(CLIENTS)" \
		-var="client_machine_type=$(CLIENT_MACHINE_TYPE)" \
		-var="server_machine_type=$(SERVER_MACHINE_TYPE)" \
		-var="grafana_load_balancer_enabled=$(GRAFANA_LOAD_BALANCER_ENABLED)" \
		-var="grafana_dns_managed_zone_dns_name=$(GRAFANA_PUBLIC_DOMAIN)" \
		-var="dns_enabled=$(DNS_ENABLED)" \
		-var="dns_managed_zone_dns_name=$(PUBLIC_DOMAIN)" \
		-var="credentials=${GOOGLE_APPLICATION_CREDENTIALS}"

.PHONY: terraform/validate/example
terraform/validate/example: ## Validates the example Terraform config
	@cd example && terraform validate

.PHONY: terraform/plan/example
terraform/plan/example: ## Runs the Terraform plan command for the example config
	@cd example && terraform plan \
		-var="project=${GOOGLE_PROJECT}" \
		-var="credentials=${GOOGLE_APPLICATION_CREDENTIALS}"

.PHONY: terraform/apply/example
terraform/apply/example: ## Runs and auto-apporves the Terraform apply command for the example config
	@cd example && terraform apply \
		-auto-approve \
		-var="project=${GOOGLE_PROJECT}" \
		-var="credentials=${GOOGLE_APPLICATION_CREDENTIALS}"

.PHONY: terraform/destroy/example
terraform/destroy/example: ## Runs and auto-apporves the Terraform destroy command for the example config
	@cd example && terraform destroy \
		-auto-approve \
		-var="project=${GOOGLE_PROJECT}" \
		-var="credentials=${GOOGLE_APPLICATION_CREDENTIALS}"

.PHONY: ssh/client
ssh/client: ## Connects to the client instance using SSH
	@gcloud compute ssh client-0 --tunnel-through-iap

.PHONY: ssh/server
ssh/server: ## Connects to the server instance using SSH
	@gcloud compute ssh server-0 --tunnel-through-iap

.PHONY: ssh/proxy/consul
ssh/proxy/consul: ## Forwards the Consul server port to localhost
	@gcloud compute ssh server-0 --tunnel-through-iap -- -f -N -L 127.0.0.1:8500:127.0.0.1:8500

.PHONY: ssh/proxy/nomad
ssh/proxy/nomad: ## Forwards the Nomad server port to localhost
	@gcloud compute ssh server-0 --tunnel-through-iap -- -f -N -L 127.0.0.1:4646:127.0.0.1:4646

.PHONY: ssh/proxy/mtls
ssh/proxy/mtls: ## Forwards the Consul and Nomad server port to localhost, using the custom mTLS terminating proxy script
	@go run ssh-mtls-terminating-proxy.go

.PHONY: ssh/proxy/count-dashboard
ssh/proxy/count-dashboard: ## Forwards the example dashboard service port to localhost
	@gcloud compute ssh client-0 --tunnel-through-iap -- -f -N -L 127.0.0.1:9002:0.0.0.0:9002

.PHONY: gcloud/delete-metadata
gcloud/delete-metadata: ## Deletes all metadata entries from client VMs
	@gcloud compute instances list | grep "client-" | awk '{print $1 " " $2}' | xargs -n2 bash -c 'gcloud compute instances remove-metadata $1 --zone=$2 --all' bash

.PHONY: consul/metrics/acls
consul/metrics/acls: ## Create a Consul policy, role, and token to use with prometheus
	@echo "📑 Creating Consul ACL Policy"
	@consul acl policy create -name "resolve-any-upstream" -rules 'service_prefix "" { policy = "read" } node_prefix "" { policy = "read" } agent_prefix "" { policy = "read" }' -token=$(shell terraform output consul_master_token)
	@echo "🎭 Creating Consul ACL Role"
	@consul acl role create -name "metrics" -policy-name  "resolve-any-upstream" -token=$(shell terraform output consul_master_token)
	@echo "🔑 Creating Consul ACL Token to Use for Prometheus Consul Service Discovery"
	@consul acl token create -role-name "metrics" -token=$(shell terraform output consul_master_token)

.PHONY: nomad/metrics
nomad/metrics: ## Runs a Prometheus and Grafana stack on Nomad
	@nomad run -var='consul_targets=[$(shell terraform output -json | jq -r '(.server_internal_ips.value + .client_internal_ips.value) | map(.+":8501") |  @csv')]' -var="consul_acl_token=$(consul_acl_token)" -var="consul_lb_ip=$(shell terraform output load_balancer_ip)" jobs/metrics/metrics.hcl

.PHONY: nomad/logs
nomad/logs: ## Runs a Loki and Promtail jobs on Nomad
	@nomad run jobs/logs/loki.hcl
	@nomad run jobs/logs/promtail.hcl

.PHONY: nomad/ingress
nomad/ingress: ## Runs a Traefik proxy to handle ingress traffic across the cluster
	@nomad run jobs/ingress/traefik.hcl

.PHONY: nomad/cockroachdb
nomad/cockroachdb: ## Runs a Cockroach DB cluster
	@nomad run jobs/db/cockroach.hcl
	@sleep 10s
	@echo "initializing database"
	@nomad alloc exec -i -t=false -task cockroach $(shell nomad status cockroach | grep "running" | grep "cockroach-1" | head -n 1 | awk '{print $$1}') cockroach init --insecure --host=localhost:26258
	@sleep 10s
	@echo "listing nodes"
	@nomad alloc exec -i -t=false -task cockroach $(shell nomad status cockroach | grep "running" | grep "cockroach-1" | head -n 1 | awk '{print $$1}') cockroach node ls --insecure --host=localhost:26258

.PHONY: nomad/cockroachdb/nodes
nomad/cockroachdb/nodes: ## List all Cockroach DB nodes
	@nomad alloc exec -i -t=false -task cockroach $(shell nomad status cockroach | grep "running" | grep "cockroach-1" | head -n 1 | awk '{print $$1}') cockroach node ls --insecure --host=localhost:26258

.PHONY: nomad/cockroachdb/sql
nomad/cockroachdb/sql: ## Start an interactive Cockroach DB SQL shell
	@nomad alloc exec -i -t=true -task cockroach $(shell nomad status cockroach | grep "running" | grep "cockroach-1" | head -n 1 | awk '{print $$1}') cockroach sql --insecure --host=localhost:26258

.PHONY: nomad/bootstrap
nomad/bootstrap: ## Bootstraps the ACL system on the Nomad cluster
	@nomad acl bootstrap

.PHONY: mtls/init/macos/keychain
mtls/init/macos/keychain: ## Create a new macOS keychain for Nomad
	@security create-keychain -P nomad

.PHONY: mtls/install/macos/keychain
mtls/install/macos/keychain: ## Install generated CA and client certificate in the macOS keychain
	@openssl pkcs12 -export -in nomad-cli-cert.pem -inkey nomad-cli-key.pem -out nomad-cli.p12 -CAfile nomad-ca.pem -name "Nomad CLI"
	@security import nomad-cli.p12 -k $(shell realpath ~/Library/Keychains/nomad-db)
	@sudo security add-trusted-cert -d -r trustRoot -k "/Library/Keychains/System.keychain" nomad-ca.pem

.PHONY: mtls/proxy/nomad
mtls/proxy/nomad: # Start mTLS local proxy for Nomad using github.com/picatz/mtls-proxy
	@mtls-proxy -listener-addr="127.0.0.1:4646" -target-addr="$(shell terraform output -raw load_balancer_ip):4646" -ca-file="nomad-ca.pem" -cert-file="nomad-cli-cert.pem" -key-file="nomad-cli-key.pem"  -verify-dns-name="server.global.nomad"

.PHONY: mtls/proxy/consul
mtls/proxy/consul: # Start mTLS local proxy for Consul using github.com/picatz/mtls-proxy
	@mtls-proxy -listener-addr="127.0.0.1:8500" -target-addr="$(shell terraform output -raw load_balancer_ip):8501" -ca-file="consul-ca.pem" -cert-file="consul-cli-cert.pem" -key-file="consul-cli-key.pem"  -verify-dns-name="server.dc1.consul"
