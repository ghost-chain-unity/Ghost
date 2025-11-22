# Ghost Protocol Kubernetes Deployment Makefile
# Provides convenient targets for common K8s operations

.PHONY: help
help: ## Show this help message
	@echo "Ghost Protocol Kubernetes Deployment"
	@echo "====================================="
	@echo ""
	@echo "Available targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-30s\033[0m %s\n", $$1, $$2}'

# ============================================================================
# Environment Generation
# ============================================================================

.PHONY: gen-env-dev gen-env-staging gen-env-prod gen-env-all
gen-env-dev: ## Generate .env file for dev environment
	@echo "Generating .env for development..."
	@./scripts/generate-env-from-terraform.sh dev

gen-env-staging: ## Generate .env file for staging environment
	@echo "Generating .env for staging..."
	@./scripts/generate-env-from-terraform.sh staging

gen-env-prod: ## Generate .env file for production environment
	@echo "Generating .env for production..."
	@./scripts/generate-env-from-terraform.sh production

gen-env-all: gen-env-dev gen-env-staging gen-env-prod ## Generate .env files for all environments

# ============================================================================
# Kustomize Build (Dry-run)
# ============================================================================

.PHONY: build-dev build-staging build-prod
build-dev: gen-env-dev ## Build Kustomize manifests for dev
	@echo "Building dev manifests..."
	@kubectl kustomize overlays/dev > /tmp/ghost-protocol-dev.yaml
	@echo "✅ Manifests saved to /tmp/ghost-protocol-dev.yaml"

build-staging: gen-env-staging ## Build Kustomize manifests for staging
	@echo "Building staging manifests..."
	@kubectl kustomize overlays/staging > /tmp/ghost-protocol-staging.yaml
	@echo "✅ Manifests saved to /tmp/ghost-protocol-staging.yaml"

build-prod: gen-env-prod ## Build Kustomize manifests for production
	@echo "Building production manifests..."
	@kubectl kustomize overlays/production > /tmp/ghost-protocol-prod.yaml
	@echo "✅ Manifests saved to /tmp/ghost-protocol-prod.yaml"

# ============================================================================
# Deployment
# ============================================================================

.PHONY: deploy-dev deploy-staging deploy-prod
deploy-dev: gen-env-dev ## Deploy to dev environment
	@echo "Deploying to dev environment..."
	@kubectl apply -k overlays/dev
	@echo "✅ Deployment complete"

deploy-staging: gen-env-staging ## Deploy to staging environment
	@echo "Deploying to staging environment..."
	@kubectl apply -k overlays/staging
	@echo "✅ Deployment complete"

deploy-prod: gen-env-prod ## Deploy to production environment
	@echo "⚠️  WARNING: Deploying to PRODUCTION"
	@read -p "Are you sure? (yes/no): " confirm && [ "$$confirm" = "yes" ] || (echo "Deployment cancelled" && exit 1)
	@echo "Deploying to production environment..."
	@kubectl apply -k overlays/production
	@echo "✅ Deployment complete"

# ============================================================================
# ArgoCD
# ============================================================================

.PHONY: argocd-install argocd-apps argocd-login argocd-status
argocd-install: ## Install ArgoCD
	@echo "Installing ArgoCD..."
	@kubectl apply -k argocd/base/
	@echo "Waiting for ArgoCD to be ready..."
	@kubectl wait --for=condition=Ready pods --all -n argocd --timeout=300s
	@echo "✅ ArgoCD installed successfully"
	@echo ""
	@echo "Get admin password:"
	@echo "  kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
	@echo ""
	@echo "Access ArgoCD UI:"
	@echo "  kubectl port-forward svc/argocd-server -n argocd 8080:443"

argocd-apps: ## Deploy ArgoCD applications
	@echo "Deploying ArgoCD applications..."
	@kubectl apply -k argocd/applications/
	@echo "✅ ArgoCD applications deployed"

argocd-login: ## Login to ArgoCD CLI
	@echo "Getting ArgoCD admin password..."
	@PASS=$$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d) && \
	echo "Password: $$PASS" && \
	argocd login localhost:8080 --username admin --password $$PASS --insecure

argocd-status: ## Check ArgoCD application status
	@argocd app list

# ============================================================================
# Verification
# ============================================================================

.PHONY: verify-dev verify-staging verify-prod
verify-dev: ## Verify dev deployment
	@echo "Verifying dev deployment..."
	@kubectl get all -n ghost-protocol-dev
	@echo ""
	@echo "Checking ServiceAccount IRSA annotations:"
	@kubectl get sa -n ghost-protocol-dev -o yaml | grep role-arn || echo "No IRSA annotations found"

verify-staging: ## Verify staging deployment
	@echo "Verifying staging deployment..."
	@kubectl get all -n ghost-protocol-staging
	@echo ""
	@echo "Checking ServiceAccount IRSA annotations:"
	@kubectl get sa -n ghost-protocol-staging -o yaml | grep role-arn || echo "No IRSA annotations found"

verify-prod: ## Verify production deployment
	@echo "Verifying production deployment..."
	@kubectl get all -n ghost-protocol-prod
	@echo ""
	@echo "Checking ServiceAccount IRSA annotations:"
	@kubectl get sa -n ghost-protocol-prod -o yaml | grep role-arn || echo "No IRSA annotations found"

# ============================================================================
# Cleanup
# ============================================================================

.PHONY: clean-dev clean-staging clean-prod clean-all
clean-dev: ## Delete dev environment
	@echo "⚠️  WARNING: This will delete all resources in ghost-protocol-dev"
	@read -p "Are you sure? (yes/no): " confirm && [ "$$confirm" = "yes" ] || (echo "Cleanup cancelled" && exit 1)
	@kubectl delete -k overlays/dev
	@echo "✅ Dev environment deleted"

clean-staging: ## Delete staging environment
	@echo "⚠️  WARNING: This will delete all resources in ghost-protocol-staging"
	@read -p "Are you sure? (yes/no): " confirm && [ "$$confirm" = "yes" ] || (echo "Cleanup cancelled" && exit 1)
	@kubectl delete -k overlays/staging
	@echo "✅ Staging environment deleted"

clean-prod: ## Delete production environment
	@echo "⚠️  WARNING: This will delete all resources in PRODUCTION"
	@echo "⚠️  This is a DESTRUCTIVE operation!"
	@read -p "Type 'DELETE PRODUCTION' to confirm: " confirm && [ "$$confirm" = "DELETE PRODUCTION" ] || (echo "Cleanup cancelled" && exit 1)
	@kubectl delete -k overlays/production
	@echo "✅ Production environment deleted"

clean-all: clean-dev clean-staging clean-prod ## Delete all environments

# ============================================================================
# Utilities
# ============================================================================

.PHONY: validate-dev validate-staging validate-prod
validate-dev: ## Validate dev Kustomize configuration
	@echo "Validating dev Kustomize configuration..."
	@kubectl kustomize overlays/dev > /dev/null && echo "✅ Dev configuration valid"

validate-staging: ## Validate staging Kustomize configuration
	@echo "Validating staging Kustomize configuration..."
	@kubectl kustomize overlays/staging > /dev/null && echo "✅ Staging configuration valid"

validate-prod: ## Validate production Kustomize configuration
	@echo "Validating production Kustomize configuration..."
	@kubectl kustomize overlays/production > /dev/null && echo "✅ Production configuration valid"

.PHONY: logs
logs: ## Tail logs for a service (usage: make logs SVC=api-gateway ENV=dev)
	@if [ -z "$(SVC)" ] || [ -z "$(ENV)" ]; then \
		echo "Usage: make logs SVC=<service> ENV=<environment>"; \
		echo "Example: make logs SVC=api-gateway ENV=dev"; \
		exit 1; \
	fi
	@NAMESPACE=ghost-protocol-$(ENV) && \
	POD=$$(kubectl get pods -n $$NAMESPACE -l app=$(SVC) -o jsonpath='{.items[0].metadata.name}') && \
	kubectl logs -f -n $$NAMESPACE $$POD

.PHONY: shell
shell: ## Open shell in a service pod (usage: make shell SVC=api-gateway ENV=dev)
	@if [ -z "$(SVC)" ] || [ -z "$(ENV)" ]; then \
		echo "Usage: make shell SVC=<service> ENV=<environment>"; \
		echo "Example: make shell SVC=api-gateway ENV=dev"; \
		exit 1; \
	fi
	@NAMESPACE=ghost-protocol-$(ENV) && \
	POD=$$(kubectl get pods -n $$NAMESPACE -l app=$(SVC) -o jsonpath='{.items[0].metadata.name}') && \
	kubectl exec -it -n $$NAMESPACE $$POD -- /bin/sh

.DEFAULT_GOAL := help
