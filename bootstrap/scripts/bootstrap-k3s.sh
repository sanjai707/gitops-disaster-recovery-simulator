#!/usr/bin/env bash

set -Eeuo pipefail

readonly LOG_FILE="/var/log/bootstrap-k3s.log"
readonly K3S_KUBECONFIG="/etc/rancher/k3s/k3s.yaml"
readonly K3S_INSTALL_URL="https://get.k3s.io"

log() {
    printf '[%s] %s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" "$*"
}

on_error() {
    local exit_code=$?
    log "Bootstrap failed at line ${BASH_LINENO[0]} with exit code ${exit_code}."
    if command -v systemctl >/dev/null 2>&1; then
        log "Recent k3s service logs:"
        systemctl --no-pager --full status k3s.service || true
        journalctl --no-pager -u k3s.service -n 50 || true
    fi
    exit "$exit_code"
}

trap on_error ERR

if [[ "${EUID}" -ne 0 ]]; then
    printf 'This script must run as root. Use: sudo %s\n' "$0" >&2
    exit 1
fi

mkdir -p "$(dirname "$LOG_FILE")"
exec > >(tee -a "$LOG_FILE") 2>&1

log "Starting single-node k3s development host bootstrap."

if [[ ! -r /etc/os-release ]]; then
    log "Cannot identify the operating system: /etc/os-release is missing."
    exit 1
fi

# shellcheck disable=SC1091
source /etc/os-release
if [[ "${ID:-}" != "ubuntu" && "${ID_LIKE:-}" != *debian* ]]; then
    log "Unsupported operating system: ${PRETTY_NAME:-unknown}. Ubuntu or Debian compatibility is required."
    exit 1
fi
log "Operating system accepted: ${PRETTY_NAME:-${ID}}."

export DEBIAN_FRONTEND=noninteractive
log "Updating apt package metadata."
apt-get update

log "Installing required bootstrap dependencies."
apt-get install --yes --no-install-recommends ca-certificates curl

if command -v k3s >/dev/null 2>&1 && systemctl is-active --quiet k3s.service; then
    log "k3s is already installed and active; skipping installation."
elif command -v k3s >/dev/null 2>&1; then
    log "k3s is installed but inactive; starting the existing service."
    systemctl start k3s.service
else
    log "Installing the latest stable k3s release from ${K3S_INSTALL_URL}."
    curl --fail --silent --show-error --location "$K3S_INSTALL_URL" | sh -s - server
fi

log "Enabling k3s at boot and waiting for the service."
systemctl enable k3s.service
systemctl start k3s.service
for attempt in {1..30}; do
    if systemctl is-active --quiet k3s.service; then
        break
    fi
    if [[ "$attempt" -eq 30 ]]; then
        log "k3s did not become active within 60 seconds."
        systemctl --no-pager --full status k3s.service || true
        exit 1
    fi
    sleep 2
done
log "k3s service is active."

if [[ ! -r "$K3S_KUBECONFIG" ]]; then
    log "k3s kubeconfig was not created at ${K3S_KUBECONFIG}."
    exit 1
fi

kubectl_k3s() {
    /usr/local/bin/k3s kubectl --kubeconfig "$K3S_KUBECONFIG" "$@"
}

log "Checking that the Kubernetes API responds."
kubectl_k3s get nodes

log "Waiting for the k3s node to become Ready."
kubectl_k3s wait --for=condition=Ready node --all --timeout=180s

TARGET_USER="${SUDO_USER:-}"
if [[ -z "$TARGET_USER" || "$TARGET_USER" == "root" ]]; then
    if id ubuntu >/dev/null 2>&1; then
        TARGET_USER="ubuntu"
    fi
fi

if [[ -n "$TARGET_USER" ]] && id "$TARGET_USER" >/dev/null 2>&1; then
    TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"
    install -d -m 700 -o "$TARGET_USER" -g "$TARGET_USER" "${TARGET_HOME}/.kube"
    install -m 600 -o "$TARGET_USER" -g "$TARGET_USER" "$K3S_KUBECONFIG" "${TARGET_HOME}/.kube/config"
    log "Configured kubectl for ${TARGET_USER}; kubeconfig remains private to this EC2 host."
else
    log "No non-root EC2 user detected; use sudo k3s kubectl for cluster access."
fi

log "Cluster node status:"
kubectl_k3s get nodes
log "All cluster pods:"
kubectl_k3s get pods --all-namespaces
log "k3s bootstrap completed successfully."
