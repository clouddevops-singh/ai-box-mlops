# Security guide

## Before exposing the service

The sample FastAPI service is unauthenticated and is intended for local demonstration. Add an authentication layer (OIDC or an identity-aware gateway), TLS, authorization, rate limits, input validation, request size limits, and audit logging before making it reachable to other users.

## Host and cluster

- Use a dedicated host, supported OS updates, SSH keys, least privilege, and no direct root SSH.
- Restrict SSH and Kubernetes API access to the management network.
- Keep the K3s admin kubeconfig private. Create scoped service accounts and RBAC for automation.
- Use Pod Security Admission or equivalent restrictive policies; run containers as non-root and drop Linux capabilities.
- Keep nodes and workloads patched. Pin tested Kubernetes, OS, driver, CUDA, and Python package versions.
- Scan and sign images; deploy by immutable digest where possible.
- Store API keys in a secret manager or encrypted Kubernetes Secrets; rotate and audit them.

## AI workload controls

- Validate prompts, file uploads, tool arguments, and model output at application boundaries.
- Restrict tools to an allowlist and apply least privilege to credentials available to an agent.
- Set token, timeout, concurrency, and cost limits for provider calls.
- Avoid logging raw prompts or sensitive data unless an approved data policy permits it.
- Do not load untrusted serialized model artifacts or Python packages on production hosts.

## Data and recovery

Define retention and deletion rules for prompts, documents, embeddings, model cache, and traces. Encrypt sensitive storage and backups. Store backups off-host and test restoring into an isolated environment. Local-path persistent volumes do not protect against disk or host loss.

## Incident response

Document who can disable ingress, revoke provider keys, isolate a node, and restore from backup. Preserve relevant audit and system logs according to retention policy. Rotate credentials after suspected exposure.
