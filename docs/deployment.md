# Deployment guide

## Host bootstrap

The bootstrap script targets Ubuntu Server 24.04 LTS and installs Docker Engine and K3s from their official installation channels. Read the script first and run from a sudo-capable account on a dedicated host:

```bash
git clone https://github.com/clouddevops-singh/ai-box-mlops.git
cd ai-box-mlops
sudo ./scripts/bootstrap-ubuntu.sh
```

Options:

```text
--skip-docker   Skip Docker Engine installation
--skip-k3s      Skip K3s installation
--no-firewall   Do not offer to configure UFW
```

The script uses official package repositories/install scripts and therefore needs outbound network access. In an air-gapped environment, use an approved package/image mirror and follow the platform's offline install procedure instead.

## Kubernetes access

The K3s kubeconfig is root-readable by default. Copy it to your user account and protect it:

```bash
mkdir -p "$HOME/.kube"
sudo install -m 0600 -o "$USER" -g "$(id -gn)" /etc/rancher/k3s/k3s.yaml "$HOME/.kube/config"
kubectl get nodes
```

For remote admin access, change the `server:` address in the copied kubeconfig to the host's private address. Do not expose TCP 6443 to an untrusted network. Create separate least-privilege Kubernetes identities for normal operations rather than sharing the admin kubeconfig.

## Build and import image

K3s uses its own containerd image store. A locally built Docker image is not visible to K3s until imported, or pushed to a registry reachable by the node:

```bash
docker build -t ai-box-api:dev ./app
docker save ai-box-api:dev | sudo k3s ctr images import -
kubectl apply -k deploy/base
kubectl -n ai-box get pods -w
```

When building for another architecture, set the correct `--platform` and verify native libraries and GPU/CUDA compatibility. For repeatable deployments, publish immutable tags or digests to a private registry and set `imagePullPolicy: IfNotPresent` or `Always` intentionally.

## Reach the API locally

```bash
kubectl -n ai-box port-forward svc/ai-box-api 8080:80
```

The sample service has no authentication. Port-forward it for local demonstration; do not publish it through a public ingress until authentication, TLS, authorization, and request controls are configured.

## Upgrade and rollback

1. Build and scan a new immutable image.
2. Update the image reference in the deployment manifest.
3. Apply the manifests and watch rollout status:

```bash
kubectl apply -k deploy/base
kubectl -n ai-box rollout status deployment/ai-box-api
```

4. Roll back an application deployment if needed:

```bash
kubectl -n ai-box rollout undo deployment/ai-box-api
```

Keep cluster upgrades separate from application releases. Back up K3s datastore and persistent data before control-plane upgrades; follow the upstream K3s upgrade and restore documentation for the chosen topology.
