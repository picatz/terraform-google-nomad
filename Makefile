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