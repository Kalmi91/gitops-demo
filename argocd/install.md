# ArgoCD install + Application

ArgoCD is installed from the **upstream stable manifests** (no fork, no Helm) so
the setup is the canonical one every ArgoCD user recognises. `make up` does all
of this; the steps are spelled out here for reference.

## 1. Install ArgoCD into the cluster

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f \
  https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl rollout status -n argocd deploy/argocd-server --timeout=300s
```

## 2. Register the Application (pull-based GitOps)

```bash
kubectl apply -f argocd/application.yaml
```

`application.yaml` points ArgoCD at this repo's `k8s/` path with
`syncPolicy.automated` (**prune + selfHeal**) and `CreateNamespace=true`, so:

- ArgoCD reconciles the desired state from Git — Git is the single source of truth.
- A manual `kubectl edit` in the cluster is reverted (selfHeal).
- A resource deleted from Git is removed from the cluster (prune).
- CI never needs cluster credentials — it only pushes images and bumps the tag
  in Git (see ADR-002).

## 3. Open the UI

```bash
make ui   # prints the admin password + port-forwards https://localhost:8080
```

## Why upstream manifests (not Helm)?

Smallest surface for a demo and identical to the official quick-start, so the
focus stays on the **GitOps loop**, not on chart values. The app itself is
delivered the GitOps way (kustomize in `k8s/`); ArgoCD is bootstrap plumbing.
