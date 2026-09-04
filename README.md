# Project 2 — Enterprise EKS Platform

This directory extends the existing banking platform to Amazon EKS **without changing Project 1 infrastructure or Terraform state**.

## Reuse from Project 1

Project 2 will consume the existing VPC, private/public subnets, NAT/IGW and other shared outputs from the Project 1 Terraform state. The EKS stack uses its own Terraform backend key so both projects can evolve independently.

## New Project 2 components

- Amazon EKS control plane
- Managed node group(s) in existing private subnets
- EKS access entries / IAM
- OIDC / IRSA
- EKS add-ons
- AWS Load Balancer Controller
- Kubernetes manifests / Helm
- Argo CD GitOps
- HPA / PDB / NetworkPolicy
- Secrets Manager integration
- Prometheus / Grafana
- DevSecOps gates and deployment strategies

## State isolation

Project 1 state remains at:

```text
s3://banking-infra/terraform.tfstate
```

Project 2 will use:

```text
s3://banking-infra/project2-eks/terraform.tfstate
```

This avoids moving or renaming any Project 1 resources and prevents Terraform state-address churn.
