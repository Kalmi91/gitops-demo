.PHONY: help up down kind-up argocd-install app sync ui

CLUSTER ?= gitops-demo
ARGOCD_NS ?= argocd
APP_NS ?= demo
APP_NAME ?= gitops-demo

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
	  awk 'BEGIN{FS=":.*?## "}{printf "  \033[36m%-14s\033[0m %s\n",$$1,$$2}'

up: kind-up argocd-install app ## kind cluster + install ArgoCD + apply the Application
	@echo "Up. 'make ui' for the ArgoCD UI, 'make sync' to force a sync."

kind-up: ## Create the kind cluster
	@kind get clusters | grep -qx $(CLUSTER) || kind create cluster --name $(CLUSTER)
	kubectl cluster-info --context kind-$(CLUSTER)

argocd-install: ## Install ArgoCD (upstream stable manifests)
	kubectl create namespace $(ARGOCD_NS) --dry-run=client -o yaml | kubectl apply -f -
	kubectl apply -n $(ARGOCD_NS) -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
	kubectl rollout status -n $(ARGOCD_NS) deploy/argocd-server --timeout=300s

app: ## Apply the ArgoCD Application (points at this repo's k8s/ path)
	kubectl apply -f argocd/application.yaml

sync: ## Force ArgoCD to sync the Application (no CLI login needed)
	kubectl -n $(ARGOCD_NS) patch application $(APP_NAME) --type merge \
	  -p '{"operation":{"sync":{"revision":"HEAD"}}}'

ui: ## Print the admin password + port-forward the ArgoCD UI to https://localhost:8080
	@echo "admin password:"
	@kubectl -n $(ARGOCD_NS) get secret argocd-initial-admin-secret \
	  -o jsonpath='{.data.password}' | base64 -d; echo
	@echo "UI: https://localhost:8080 (user: admin). Ctrl-C to stop."
	kubectl -n $(ARGOCD_NS) port-forward svc/argocd-server 8080:443

down: ## Delete the kind cluster — back to $$0
	-kind delete cluster --name $(CLUSTER)
	@echo "All down."
