# Hardware and OS setup

## Reference hardware

Choose hardware for the model and concurrency target. The following is a starting point for a small lab, not a sizing guarantee:

| Component | Starting point | Notes |
|---|---|---|
| CPU | 4+ modern x86_64 cores | More cores help API concurrency, preprocessing, and embedding tasks. |
| Memory | 16+ GB | Model memory is separate from the base platform requirement. |
| Storage | 250+ GB SSD/NVMe | Keep model cache, container layers, logs, and persistent data in mind. |
| Network | 1 GbE, private LAN | Use a dedicated management segment where possible. |
| GPU (optional) | NVIDIA GPU supported by current driver/operator | VRAM must fit the model and expected batch/concurrency. |
| Power | UPS recommended | Use protected shutdown for stateful workloads. |

## Install Ubuntu Server

1. Download the current Ubuntu Server 24.04 LTS image from Canonical and verify its checksum/signature.
2. Write the image to USB using a trusted imaging tool.
3. Install to the intended system disk. Select OpenSSH Server only if remote administration is needed.
4. Create a named administrator account, use an SSH public key, and avoid enabling direct root login.
5. Configure a static DHCP reservation or stable private address. Record the address, MAC, disk layout, and recovery method.
6. Apply firmware updates and enable UEFI Secure Boot when compatible with the GPU driver and operational requirements.
7. On first boot, update the system and reboot:

```bash
sudo apt update
sudo apt full-upgrade -y
sudo reboot
```

Use the vendor's installation guide for the selected GPU/host; this project does not provide an unattended OS installer because disk device names, boot mode, network, and SSH keys are machine-specific.

## Prepare access

From the management machine, use SSH keys and restrict source addresses at the network edge. On the server, verify time synchronization, DNS, hostname, and disk capacity:

```bash
hostnamectl
timedatectl status
ip address
df -h
```

For isolated networks, pre-stage trusted OS packages and container images in an internal mirror. Do not bypass signature checks to work around missing connectivity.

## Before bootstrap

- Reserve the host address and decide which LANs may access SSH, Kubernetes API, and application ingress.
- Keep SSH reachable from your management network before enabling a host firewall.
- Choose whether the machine is a lab single node or the first node in a multi-node cluster.
- For GPU nodes, install and validate the host driver before installing the GPU Operator, following NVIDIA's compatibility guidance.
- Back up any existing data on the target host. Bootstrap is intended for a fresh, dedicated host.
