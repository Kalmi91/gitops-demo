# Decisions (ADR-lite)

Context → decision → consequence → trade-off. Doubles as interview talking
points.

## ADR-001 — kind instead of a managed cluster
- **Context:** Need Kubernetes to run ArgoCD + the app, at $0.
- **Decision:** kind (Kubernetes-in-Docker) locally.
- **Consequence:** Real k8s + real ArgoCD, no cloud bill.
- **Trade-off:** No cloud LoadBalancer/ingress specifics; port-forward instead.

## ADR-002 — ArgoCD (pull-based GitOps) over CI `kubectl apply` (push)
- **Context:** Could deploy straight from CI with `kubectl apply`.
- **Decision:** ArgoCD reconciles desired state from Git instead.
- **Consequence:** Git is the single source of truth; drift detection + self-heal;
  CI needs no cluster credentials (smaller blast radius).
- **Trade-off:** One more component to run; slight indirection. This is the whole
  point of the project — showing the GitOps model, not just a deploy script.

## ADR-003 — GHCR for images
- **Context:** Need a registry the cluster can pull from, free.
- **Decision:** GitHub Container Registry (GHCR), public image, `GITHUB_TOKEN`.
- **Consequence:** $0, no extra account, integrates with Actions.
- **Trade-off:** Public image (fine for a demo); private would need pull secrets.

## ADR-004 — Image tag = git SHA (immutable), not `latest`
- **Context:** GitOps needs a concrete version to sync to.
- **Decision:** Tag images with `${{ github.sha }}`; the manifest references the
  SHA. `latest` only as a convenience pointer.
- **Consequence:** Every deploy is traceable to a commit; rollbacks are trivial.
- **Trade-off:** Manifest must be bumped per release (Q6 automates this).

## ADR-005 — Multi-stage Dockerfile / minimal base
- **Context:** Image hygiene is a visible skill.
- **Decision:** Multi-stage build, distroless/alpine final stage.
- **Consequence:** Small, fewer CVEs.
- **Trade-off:** Slightly more Dockerfile complexity.

## ADR-006 — Agent writes code, user runs the runtime
- **Context:** The Claude Code sandbox has no Docker socket and can't start a
  daemon (bwrap namespace).
- **Decision:** Agent authors code + offline checks; user runs Docker/kind/ArgoCD.
- **Consequence:** Token-burn build sessions stay productive; never block.
- **Trade-off:** End-to-end verification deferred to the user's `make up`.

## ADR-007 — Image-tag bump via commit-back, not argocd-image-updater
- **Context:** ArgoCD syncs *what Git says*. After CI pushes `image:sha`, Git
  must reference that new tag for the deploy to happen. Two ways: a CI job that
  rewrites the manifest and commits back, or `argocd-image-updater` watching the
  registry.
- **Decision:** CI `bump-manifest` job edits `k8s/kustomization.yaml`'s `newTag`
  to `sha-<commit>` and commits with `[skip ci]` (which prevents a rebuild loop,
  since the bump touches only `k8s/` — no new image to build).
- **Consequence:** The whole loop is plain Git — the bump commit is the audit
  trail; rollback = `git revert`; no extra in-cluster controller to run.
- **Trade-off:** A bot commit per release; needs `contents: write`. Image-updater
  would avoid the commit but adds a component and registry-poll config — overkill
  for a single-app demo whose *point* is showing the Git-driven loop.
