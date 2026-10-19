# Operations and resilience

## Routine checks

```bash
kubectl get nodes
kubectl get pods -A
kubectl -n ai-box get deploy,svc,networkpolicy
sudo systemctl status k3s
sudo journalctl -u k3s --since '1 hour ago'
df -h
```

Monitor node CPU, memory, disk/inodes, temperature, API request latency and errors, pod restarts, pending pods, GPU utilization and memory, driver/operator health, and backup freshness. Alert on node NotReady, persistent volume pressure, repeated restarts, sustained API errors, and exhausted GPU capacity.

## Load evaluation

Use a dedicated test environment or agreed maintenance window. Ramp concurrency gradually and record hardware, model, image digest, request distribution, warm-up, test duration, and result. Measure p50/p95/p99 latency, throughput, error rate, CPU/memory, GPU utilization/VRAM, and queue depth. Do not publish benchmark claims without reproducible measurements.

## Failure exercises

On a disposable or maintenance-approved cluster, test one failure at a time:

- Restart the API pod and confirm readiness removes it from service until it is healthy.
- Stop a worker or reboot the single node and document the expected downtime and recovery steps.
- Fill a test filesystem or exhaust a test resource quota to confirm alerts and scheduling behavior.
- Deny model egress and confirm the API fails safely with bounded timeouts.
- For multi-node clusters, drain a worker and verify workload rescheduling and storage behavior.

Avoid running arbitrary chaos tooling against production without a scoped experiment and rollback plan. A single-node cluster cannot demonstrate node failover or control-plane high availability.

## Backup and restore

Back up the K3s datastore and all persistent application/model data using the method appropriate to the topology. Encrypt backups, keep copies off-host, record retention and ownership, and test restore regularly. For embedded etcd, use supported K3s etcd snapshot procedures. For a single-node SQLite setup, follow K3s backup/restore guidance and stop or quiesce writes as required. Do not treat a filesystem copy of a live datastore as a valid backup without testing it.

## Upgrade process

1. Read release notes for Ubuntu, K3s, GPU Operator, driver, and application dependencies.
2. Back up datastore and persistent data.
3. Upgrade a staging or lab node first.
4. Validate API health, network policies, GPU allocation, and restore procedures.
5. Upgrade production nodes in the topology's supported order and monitor.
