#!/usr/bin/env bash
set -euo pipefail

SKIP_DOCKER=false
SKIP_K3S=false
CONFIGURE_FIREWALL=true
for arg in "$@"; do
  case "$arg" in
    --skip-docker) SKIP_DOCKER=true ;;
    --skip-k3s) SKIP_K3S=true ;;
    --no-firewall) CONFIGURE_FIREWALL=false ;;
    *) echo "Unknown option: $arg" >&2; exit 2 ;;
  esac
done

if [[ "${EUID}" -ne 0 ]]; then
  echo "Run with sudo: sudo $0 [--skip-docker] [--skip-k3s] [--no-firewall]" >&2
  exit 1
fi

if [[ ! -r /etc/os-release ]]; then
  echo "Cannot identify operating system." >&2
  exit 1
fi
# shellcheck disable=SC1091
source /etc/os-release
if [[ "${ID:-}" != "ubuntu" || "${VERSION_ID:-}" != "24.04" ]]; then
  echo "This script supports Ubuntu Server 24.04 LTS. Found ${PRETTY_NAME:-unknown}." >&2
  exit 1
fi

echo "This will install host packages and may install Docker and K3s."
read -r -p "Continue on this dedicated host? [y/N] " answer
[[ "$answer" =~ ^[Yy]$ ]] || { echo "Cancelled."; exit 0; }

apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y ca-certificates curl gnupg ufw

if [[ "$SKIP_DOCKER" == false ]]; then
  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
  chmod a+r /etc/apt/keyrings/docker.asc
  arch="$(dpkg --print-architecture)"
  codename="$(. /etc/os-release && echo "$VERSION_CODENAME")"
  printf 'Types: deb\nURIs: https://download.docker.com/linux/ubuntu\nSuites: %s\nComponents: stable\nArchitectures: %s\nSigned-By: /etc/apt/keyrings/docker.asc\n' "$codename" "$arch" > /etc/apt/sources.list.d/docker.sources
  apt-get update
  DEBIAN_FRONTEND=noninteractive apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  systemctl enable --now docker
fi

if [[ "$SKIP_K3S" == false ]]; then
  # Pin a tested K3s version through INSTALL_K3S_VERSION before using this in a
  # controlled environment. The upstream installer resolves the current stable release.
  curl -sfL https://get.k3s.io | sh -s - --write-kubeconfig-mode 600
  systemctl enable --now k3s
fi

if [[ "$CONFIGURE_FIREWALL" == true ]]; then
  echo "UFW is currently: $(ufw status | head -n 1)"
  read -r -p "Configure UFW allowing SSH and optional K3s API only from trusted CIDRs? [y/N] " firewall_answer
  if [[ "$firewall_answer" =~ ^[Yy]$ ]]; then
    read -r -p "Trusted management CIDR for SSH (example 192.168.10.0/24): " ssh_cidr
    [[ -n "$ssh_cidr" ]] || { echo "SSH CIDR is required; leaving firewall unchanged."; exit 1; }
    ufw default deny incoming
    ufw default allow outgoing
    ufw allow from "$ssh_cidr" to any port 22 proto tcp
    if [[ "$SKIP_K3S" == false ]]; then
      read -r -p "Trusted CIDR for Kubernetes API 6443 (blank to omit): " api_cidr
      if [[ -n "$api_cidr" ]]; then ufw allow from "$api_cidr" to any port 6443 proto tcp; fi
    fi
    ufw --force enable
  else
    echo "Leaving UFW policy unchanged. Apply firewall rules at the host or network edge."
  fi
fi

echo "Bootstrap complete. Review docs/deployment.md and docs/network-isolation.md before deploying workloads."
