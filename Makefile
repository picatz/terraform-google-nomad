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

.PHONY: packer/validate
packer/validate: ## Validates the Packer config
	cd packer && packer validate template.json

.PHONY: packer/build
packer/build: ## Forces a build with Packer
	cd packer && time packer build \
		-force \
		-timestamp-ui \
		template.json

.PHONY: terraform/validate
terraform/validate: ## Validates the Terraform config
	terraform validate

.PHONY: terraform/plan
terraform/plan: ## Runs the Terraform plan command
	terraform plan \
		-var="project=${GOOGLE_PROJECT}" \
		-var="credentials=${GOOGLE_APPLICATION_CREDENTIALS}"

.PHONY: terraform/apply
terraform/apply: ## Runs and auto-apporves the Terraform apply command
	terraform apply \
		-auto-approve \
		-var="project=${GOOGLE_PROJECT}" \
		-var="credentials=${GOOGLE_APPLICATION_CREDENTIALS}"

.PHONY: terraform/destroy
terraform/destroy: ## Runs and auto-apporves the Terraform destroy command
	terraform destroy \
		-auto-approve \
		-var="project=${GOOGLE_PROJECT}" \
		-var="credentials=${GOOGLE_APPLICATION_CREDENTIALS}"

.PHONY: terraform/validate/example
terraform/validate/example: ## Validates the example Terraform config
	cd example && terraform validate

.PHONY: terraform/plan/example
terraform/plan/example: ## Runs the Terraform plan command for the example config
	cd example && terraform plan \
		-var="project=${GOOGLE_PROJECT}" \
		-var="credentials=${GOOGLE_APPLICATION_CREDENTIALS}"

.PHONY: terraform/apply/example
terraform/apply/example: ## Runs and auto-apporves the Terraform apply command for the example config
	cd example && terraform apply \
		-auto-approve \
		-var="project=${GOOGLE_PROJECT}" \
		-var="credentials=${GOOGLE_APPLICATION_CREDENTIALS}"

.PHONY: terraform/destroy/example
terraform/destroy/example: ## Runs and auto-apporves the Terraform destroy command for the example config
	cd example && terraform destroy \
		-auto-approve \
		-var="project=${GOOGLE_PROJECT}" \
		-var="credentials=${GOOGLE_APPLICATION_CREDENTIALS}"

.PHONY: ssh/client
ssh/client: ## Connects to the client instance using SSH
	gcloud compute ssh client-0 --tunnel-through-iap

.PHONY: ssh/server
ssh/server: ## Connects to the server instance using SSH
	gcloud compute ssh server-0 --tunnel-through-iap

.PHONY: ssh/proxy/consul
ssh/proxy/consul: ## Forwards the Consul server port to localhost
	gcloud compute ssh server-0 --tunnel-through-iap -- -f -N -L 127.0.0.1:8500:127.0.0.1:8500

.PHONY: ssh/proxy/nomad
ssh/proxy/nomad: ## Forwards the Nomad server port to localhost
	gcloud compute ssh server-0 --tunnel-through-iap -- -f -N -L 127.0.0.1:4646:127.0.0.1:4646

.PHONY: ssh/proxy/mtls
ssh/proxy/mtls: ## Forwards the Consul and Nomad server port to localhost, using the custom mTLS terminating proxy script
	go run ssh-mtls-terminating-proxy.go

.PHONY: ssh/proxy/count-dashboard
ssh/proxy/count-dashboard: ## Forwards the example dashboard serverive port to localhost
	gcloud compute ssh client-0 --tunnel-through-iap -- -f -N -L 127.0.0.1:9002:0.0.0.0:9002