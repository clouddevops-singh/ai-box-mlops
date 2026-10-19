# Network isolation

## Host boundary

Place the AI box on a private network. Permit SSH only from the management subnet, Kubernetes API only from trusted operators, and application ingress only from intended clients. Do not expose K3s TCP 6443, etcd ports, kubelet ports, or node exporter ports to the public internet.

The bootstrap script offers UFW rules for SSH and Kubernetes API access. It asks for trusted CIDRs; inspect them carefully and preserve a working SSH session. Firewall rules supplement network controls and should be reviewed against the actual host interface and routing design.

## Kubernetes boundary

The `ai-box` namespace has default-deny ingress and egress policies plus narrow DNS and API-ingress examples. Network policy is enforced only by a compatible CNI policy implementation. Verify K3s is running its network policy controller and test from a temporary pod before treating isolation as effective.

Policies are in [../deploy/base/network-policy.yaml](../deploy/base/network-policy.yaml). The API is not exposed by a NodePort or public LoadBalancer. Add an ingress controller and an explicit ingress allow policy only after defining authentication and TLS.

## Egress policy

The reference policy allows cluster DNS and denies other namespace egress by default. If the application calls an internal model service, add a narrow namespace/pod selector rule. If it calls an external provider, destination IPs may change; use a controlled egress proxy or gateway with hostname policy and audit logging rather than a broad all-internet allow rule.

NetworkPolicy does not replace host firewall rules, cloud security groups, authentication, TLS, or workload identity. Standard Kubernetes policy cannot express arbitrary DNS hostname rules, and enforcement details vary by CNI.

## Validation checklist

1. From a test pod, confirm DNS works.
2. Confirm a pod cannot reach an unrelated namespace by default.
3. Confirm the API is reachable only through its intended service path.
4. Confirm approved model/provider destinations work and unapproved egress fails.
5. Repeat after cluster or CNI upgrades.
