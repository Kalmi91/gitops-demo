#!/usr/bin/env bash
# Installs the gitops-demo toolchain into ~/.local/bin and ensures Docker is
# usable. Run once on the HOST shell (needs the Docker daemon + real sudo —
# not the Claude Code sandbox).
#
#   ./scripts/bootstrap.sh
#
# Idempotent: skips anything already installed.
set -euo pipefail

BIN="${HOME}/.local/bin"
mkdir -p "$BIN"
case ":$PATH:" in
  *":$BIN:"*) ;;
  *) echo "WARNING: $BIN is not on your PATH. Add to ~/.bashrc:"
     echo '  export PATH="$HOME/.local/bin:$PATH"' ;;
esac

KIND_VERSION="v0.27.0"

have() { command -v "$1" >/dev/null 2>&1; }

# --- kubectl -----------------------------------------------------------------
if have kubectl; then
  echo "kubectl: present"
else
  echo "kubectl: installing latest stable"
  ver="$(curl -fsSL https://dl.k8s.io/release/stable.txt)"
  curl -fsSL -o "$BIN/kubectl" "https://dl.k8s.io/release/${ver}/bin/linux/amd64/kubectl"
  chmod +x "$BIN/kubectl"
fi

# --- kind --------------------------------------------------------------------
if have kind; then
  echo "kind: present"
else
  echo "kind: installing ${KIND_VERSION}"
  curl -fsSL -o "$BIN/kind" "https://kind.sigs.k8s.io/dl/${KIND_VERSION}/kind-linux-amd64"
  chmod +x "$BIN/kind"
fi

# --- argocd CLI --------------------------------------------------------------
if have argocd; then
  echo "argocd: present"
else
  echo "argocd: installing latest"
  curl -fsSL -o "$BIN/argocd" \
    https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
  chmod +x "$BIN/argocd"
fi

# --- Docker daemon -----------------------------------------------------------
if docker ps >/dev/null 2>&1; then
  echo "docker: daemon reachable"
else
  echo "docker: starting daemon (needs sudo)"
  sudo systemctl start docker || sudo service docker start
  if ! id -nG "$USER" | grep -qw docker; then
    echo "docker: adding $USER to the docker group (re-login afterwards)"
    sudo usermod -aG docker "$USER"
    echo "  --> run 'newgrp docker' or re-login, then re-run this script"
  fi
fi

echo
echo "bootstrap done. Versions:"
for t in kubectl kind argocd; do
  have "$t" && printf '  %-9s %s\n' "$t" "$($t version --client 2>/dev/null | head -1)"
done
