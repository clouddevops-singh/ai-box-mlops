# GPU scheduling

This guide uses the NVIDIA GPU Operator as the supported integration path. It is optional; CPU-only clusters can skip this entire guide.

## Prerequisites

- NVIDIA GPU supported by the current driver and GPU Operator release.
- Ubuntu kernel and host configuration supported by the selected driver.
- A working K3s cluster and Helm 3.
- Outbound access to the NVIDIA GPU Operator chart/image registry, or an approved mirror.
- Compatibility checked between GPU, driver, CUDA runtime in the workload image, and framework build.

Install and verify the NVIDIA driver on the host using NVIDIA's supported package/repository instructions. Confirm `nvidia-smi` works before installing the operator. Avoid installing a second container toolkit configuration that conflicts with the operator-managed runtime components.

## Install GPU Operator

Use the current release and values from NVIDIA's official documentation, then record the selected chart version in your deployment change log. Example Helm flow:

```bash
helm repo add nvidia https://helm.ngc.nvidia.com/nvidia
helm repo update
helm upgrade --install gpu-operator nvidia/gpu-operator \
  --namespace gpu-operator --create-namespace
kubectl get pods -n gpu-operator -w
kubectl describe node "$(kubectl get nodes -o jsonpath='{.items[0].metadata.name}')" | grep -A5 -E 'Capacity|Allocatable'
```

Do not assume the example chart version is suitable indefinitely. Pin the validated version in a Helm values/lock file before production deployment. If the operator is configured not to manage drivers, install and maintain drivers on the host yourself.

## Label eligible nodes

On multi-node clusters, mark only GPU nodes for GPU inference:

```bash
kubectl label node <gpu-node-name> ai-box.example.com/gpu=true
```

## Request a GPU

The example overlay adds a GPU-limited deployment and requires the GPU node label:

```bash
kubectl apply -k deploy/gpu
kubectl -n ai-box get pods -o wide
kubectl -n ai-box describe pod -l app=ai-box-gpu-demo
```

Kubernetes schedules GPU resources as integer extended resources, typically `nvidia.com/gpu`. Set that resource in `limits`; Kubernetes uses the limit as the request if a separate request is omitted. A node with no free GPU remains unsuitable and the pod stays Pending.

## Capacity and fairness

- One allocated GPU is normally exclusive to one pod; use supported MIG profiles or time-slicing only after validating the GPU and workload behavior.
- Extended GPU resources cannot be overcommitted like CPU. Monitor allocatable capacity and pending pods.
- Set CPU and memory requests/limits alongside GPU allocation.
- Add priority classes and quotas if teams share the cluster.
- A GPU resource request only reserves a device. The image and framework must use CUDA to gain acceleration.

## Troubleshooting

```bash
kubectl get pods -n gpu-operator
kubectl describe node <gpu-node-name>
kubectl describe pod -n ai-box <gpu-pod>
```

Check driver health, operator daemonsets, `nvidia.com/gpu` allocatable capacity, runtime compatibility, image CUDA support, node selectors, and taints. Consult NVIDIA's current troubleshooting guidance before changing driver or runtime settings.
