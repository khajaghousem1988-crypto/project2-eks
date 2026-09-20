# Project 2 – Enterprise Amazon EKS Platform with Helm & GitOps

## 1. Overview

This project implements an enterprise-style container platform on AWS using Amazon EKS.

The platform provisions Kubernetes infrastructure using Terraform, stores application images in Amazon ECR, deploys workloads using Kubernetes and Helm, and exposes the application through an AWS Application Load Balancer using the AWS Load Balancer Controller.

The project is intentionally maintained separately from Project 1 (ECS/Fargate).

### High-Level Flow

```text
Developer
   |
   | git clone
   v
Git Repository
   |
   +----------------------+
   |                      |
   v                      v
Terraform              Application
   |                      |
   v                      v
AWS Infrastructure     Docker Build
   |                      |
   |                      v
   |                  Amazon ECR
   |                      |
   v                      v
Amazon EKS <--------- Kubernetes / Helm
   |
   v
Kubernetes Deployment
   |
   v
ClusterIP Service
   |
   v
Ingress
   |
   v
AWS Load Balancer Controller
   |
   v
Internet-Facing ALB
   |
   v
Browser
```

---

# 2. Technology Stack

| Layer | Technology |
|---|---|
| Cloud | AWS |
| Infrastructure as Code | Terraform |
| Container Runtime | Docker |
| Container Registry | Amazon ECR |
| Kubernetes | Amazon EKS |
| Package Management | Helm |
| Ingress | Kubernetes Ingress |
| Load Balancer | AWS Application Load Balancer |
| ALB Integration | AWS Load Balancer Controller |
| IAM Integration | IAM / IRSA |
| Networking | VPC, Public/Private Subnets, NAT Gateway, IGW |
| Application | Python / Flask / Gunicorn |
| GitOps | Argo CD – planned |
| Monitoring | Prometheus/Grafana – planned |

> Do not mark Argo CD or Prometheus/Grafana as implemented until those components have been deployed and validated.

---

# 3. Project Separation

Project 1 and Project 2 are intentionally separated.

```text
banking-devops-platform/
│
├── app/                         # Project 1 application
├── iac/                         # Project 1 ECS infrastructure
│
└── project2-eks/
    ├── app/                     # Project 2 application
    ├── iac/                     # Project 2 Terraform
    ├── kubernetes/              # Kubernetes manifests
    ├── helm/                    # Helm charts
    ├── argocd/                  # GitOps configuration
    ├── monitoring/              # Monitoring configuration
    ├── policies/                # Security/policy definitions
    ├── scripts/                 # Operational scripts
    └── README.md
```

Project 1:

```text
Application
   ↓
banking-devops-dev-app
   ↓
Amazon ECS/Fargate
```

Project 2:

```text
project2-eks/app
   ↓
banking-eks-dev-app
   ↓
Amazon EKS
```

Do not modify Project 1 application or ECS resources while working on Project 2.

---

# 4. Current DEV Environment

## AWS

```text
AWS Account : 500788673290
Region      : us-east-1
Environment : dev
```

## Networking

Shared Project 1 VPC:

```text
VPC:
vpc-03885f609bfdced80
```

Public subnets:

```text
subnet-0faec8b50e5be1d26
subnet-0e1b81d428eeabb25
```

Private subnets:

```text
subnet-06468a3da71880bc7
subnet-0fd61fcdd328610df
```

The EKS cluster reuses the existing VPC through Terraform remote state.

---

# 5. EKS Environment

Cluster:

```text
banking-eks-dev-cluster
```

Node group:

```text
banking-eks-dev-node-group
```

Node role:

```text
banking-eks-dev-eks-node-role
```

Kubernetes version:

```text
1.36
```

Current lab worker instance type:

```text
t3.micro
```

Important:

`t3.micro` currently exposes a very small Kubernetes pod capacity in this environment.

Observed:

```text
Allocatable Pods Per Node: 4
```

Therefore this DEV environment uses conservative replica counts.

This is a lab constraint and is NOT a recommended production EKS sizing model.

---

# 6. ECR Repository

Project 2 has its own ECR repository:

```text
banking-eks-dev-app
```

Repository URI:

```text
500788673290.dkr.ecr.us-east-1.amazonaws.com/banking-eks-dev-app
```

Current application image:

```text
500788673290.dkr.ecr.us-east-1.amazonaws.com/banking-eks-dev-app:v1.0.1
```

ECR configuration includes:

```text
Image scanning on push
AES256 encryption
Immutable image tags
Terraform management
```

Because image tags are immutable, use a new version for every release.

Example:

```text
v1.0.1
v1.0.2
v1.0.3
```

Do NOT overwrite an existing tag.

---

# 7. Prerequisites for a New Engineer

Before onboarding, install:

```text
Git
AWS CLI
Terraform
kubectl
Docker
Helm
eksctl
```

Verify:

```bash
git --version
aws --version
terraform version
kubectl version --client
docker --version
helm version
eksctl version
```

Docker Desktop must be running if building images locally.

---

# 8. AWS Authentication

Confirm the correct AWS identity before doing anything.

```bash
aws sts get-caller-identity
```

Expected account:

```text
500788673290
```

Example:

```json
{
  "Account": "500788673290"
}
```

Also verify the region:

```bash
aws configure get region
```

Expected:

```text
us-east-1
```

If an AWS CLI named profile is required:

```bash
export AWS_PROFILE=<profile-name>
```

Then repeat:

```bash
aws sts get-caller-identity
```

Never run Terraform until the AWS account and region have been verified.

---

# 9. Clone the Repository

```bash
git clone <repository-url>

cd banking-devops-platform
```

Confirm Project 2:

```bash
ls project2-eks
```

Expected structure:

```text
app
argocd
helm
iac
kubernetes
monitoring
policies
scripts
README.md
```

---

# 10. Terraform Remote State

Project 2 uses its own Terraform state.

Backend:

```hcl
terraform {
  backend "s3" {
    bucket         = "banking-infra"
    key            = "project2-eks/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock-dev"
    encrypt        = true
  }
}
```

Project 2 reads networking information from Project 1 through Terraform remote state.

This allows Project 2 to reuse:

```text
VPC
Public subnet IDs
Private subnet IDs
```

without duplicating networking infrastructure.

---

# 11. Terraform Initialization

Navigate to:

```bash
cd project2-eks/iac
```

Initialize:

```bash
terraform init
```

Validate:

```bash
terraform validate
```

Format:

```bash
terraform fmt -recursive
```

Review:

```bash
terraform plan
```

IMPORTANT:

Never blindly run:

```bash
terraform apply
```

Review the entire plan first.

Expected changes must be understood before approval.

---

# 12. Known Terraform Drift

The EKS OIDC provider was associated using `eksctl`.

As a result Terraform may detect:

```text
alpha.eksctl.io/cluster-oidc-enabled
```

as an external tag.

Example plan:

```text
- "alpha.eksctl.io/cluster-oidc-enabled" = "true" -> null
```

Do NOT blindly apply this change.

For isolated module operations, a targeted apply may be used after reviewing the plan.

Example:

```bash
terraform apply -target=module.ecr
```

or:

```bash
terraform apply -target=module.eks_node_group
```

Targeted applies are an operational exception and should not replace normal Terraform lifecycle management.

The long-term objective should be to reconcile externally created configuration into Terraform.

---

# 13. Verify Existing AWS Infrastructure

Check EKS:

```bash
aws eks describe-cluster \
  --name banking-eks-dev-cluster \
  --region us-east-1 \
  --query 'cluster.status' \
  --output text
```

Expected:

```text
ACTIVE
```

Check node group:

```bash
aws eks describe-nodegroup \
  --cluster-name banking-eks-dev-cluster \
  --nodegroup-name banking-eks-dev-node-group \
  --region us-east-1 \
  --query 'nodegroup.{Status:status,Health:health}'
```

Expected status:

```text
ACTIVE
```

---

# 14. Configure kubectl

Generate/update kubeconfig:

```bash
aws eks update-kubeconfig \
  --region us-east-1 \
  --name banking-eks-dev-cluster
```

Verify context:

```bash
kubectl config current-context
```

Check cluster connectivity:

```bash
kubectl cluster-info
```

Check nodes:

```bash
kubectl get nodes
```

All worker nodes should be:

```text
Ready
```

Example:

```text
NAME                          STATUS
ip-10-0-x-x.ec2.internal     Ready
ip-10-0-x-x.ec2.internal     Ready
```

If nodes are `NotReady`, stop here and troubleshoot the cluster before deploying applications.

---

# 15. Verify Core Kubernetes Components

```bash
kubectl get pods -n kube-system
```

Validate:

```text
aws-node       Running
coredns        Running
kube-proxy     Running
```

AWS Load Balancer Controller must also be:

```text
Running
```

Check:

```bash
kubectl get deployment aws-load-balancer-controller -n kube-system
```

Current DEV environment may run one controller replica because of lab pod-capacity constraints.

Production environments should use an appropriate HA configuration.

---

# 16. EKS CNI Configuration

The EKS node IAM role requires:

```text
AmazonEKSWorkerNodePolicy
AmazonEC2ContainerRegistryPullOnly
AmazonEKS_CNI_Policy
```

The `AmazonEKS_CNI_Policy` was required to resolve CNI/IP allocation issues encountered during implementation.

Verify:

```bash
aws iam list-attached-role-policies \
  --role-name banking-eks-dev-eks-node-role
```

---

# 17. Public/Private Subnet Discovery Tags

AWS Load Balancer Controller requires appropriate subnet discovery.

Public subnets:

```text
kubernetes.io/role/elb = 1
```

Private subnets:

```text
kubernetes.io/role/internal-elb = 1
```

Validate:

```bash
aws ec2 describe-subnets \
  --subnet-ids \
  subnet-0faec8b50e5be1d26 \
  subnet-0e1b81d428eeabb25 \
  --query 'Subnets[*].{Subnet:SubnetId,AZ:AvailabilityZone,Tags:Tags}'
```

Missing subnet tags can prevent ALB provisioning.

---

# 18. AWS Load Balancer Controller

The controller uses IAM Roles for Service Accounts (IRSA).

Service account:

```text
aws-load-balancer-controller
```

Namespace:

```text
kube-system
```

Verify:

```bash
kubectl get sa aws-load-balancer-controller \
  -n kube-system \
  -o yaml
```

Look for:

```text
eks.amazonaws.com/role-arn
```

Verify controller:

```bash
kubectl get pods \
  -n kube-system \
  -l app.kubernetes.io/name=aws-load-balancer-controller
```

Expected:

```text
Running
```

---

# 19. Building the Application

Navigate to:

```bash
cd project2-eks/app
```

Login to ECR:

```bash
aws ecr get-login-password --region us-east-1 | \
docker login \
--username AWS \
--password-stdin \
500788673290.dkr.ecr.us-east-1.amazonaws.com
```

IMPORTANT FOR APPLE SILICON:

EKS worker nodes use:

```text
amd64
```

MacBook Apple Silicon normally builds:

```text
arm64
```

Therefore explicitly build the image for:

```text
linux/amd64
```

Example:

```bash
docker buildx build \
  --platform linux/amd64 \
  -t 500788673290.dkr.ecr.us-east-1.amazonaws.com/banking-eks-dev-app:v1.0.2 \
  --push .
```

Use a new image version because the ECR repository has immutable tags.

---

# 20. Verify ECR Image

```bash
aws ecr describe-images \
  --repository-name banking-eks-dev-app \
  --region us-east-1
```

To verify a specific release:

```bash
aws ecr describe-images \
  --repository-name banking-eks-dev-app \
  --region us-east-1 \
  --image-ids imageTag=v1.0.2
```

Do not proceed with Kubernetes deployment unless the image exists in ECR.

---

# 21. Kubernetes Namespace

Application namespace:

```text
banking-dev
```

Verify:

```bash
kubectl get namespace banking-dev
```

If building the environment from scratch:

```bash
kubectl apply -f project2-eks/kubernetes/base/namespace.yaml
```

---

# 22. Kubernetes Deployment Architecture

```text
Deployment
banking-app
      |
      v
Pod
Flask/Gunicorn :5000
      |
      v
Service
banking-app-service
ClusterIP :80
      |
      v
Ingress
banking-app-ingress
      |
      v
AWS Load Balancer Controller
      |
      v
ALB
      |
      v
Browser
```

---

# 23. Helm Chart

Helm chart:

```text
project2-eks/helm/banking-app
```

Structure:

```text
banking-app/
├── Chart.yaml
├── values.yaml
└── templates/
    ├── deployment.yaml
    ├── service.yaml
    └── ingress.yaml
```

Current chart:

```text
Chart Version : 0.1.0
App Version   : 1.0.1
```

---

# 24. Helm Validation

Before deploying:

```bash
cd project2-eks/helm/banking-app
```

Lint:

```bash
helm lint .
```

Expected:

```text
1 chart(s) linted, 0 chart(s) failed
```

Render:

```bash
helm template banking-app . -n banking-dev
```

Kubernetes client-side validation:

```bash
helm template banking-app . -n banking-dev | \
kubectl apply --dry-run=client -f -
```

Expected resources:

```text
service/banking-app-service
deployment.apps/banking-app
ingress.networking.k8s.io/banking-app-ingress
```

---

# 25. Helm Installation

For a clean/new environment:

```bash
helm install banking-app . \
  -n banking-dev
```

If the namespace does not exist, create it first:

```bash
kubectl create namespace banking-dev
```

For this existing environment, resources originally created using `kubectl` were adopted into Helm using:

```bash
helm install banking-app . \
  -n banking-dev \
  --take-ownership
```

Do NOT use `--take-ownership` automatically in a new environment.

It is required only when adopting existing resources after confirming that they belong to this release.

---

# 26. Helm Verification

```bash
helm list -n banking-dev
```

Check:

```bash
helm status banking-app -n banking-dev
```

Current validated release:

```text
STATUS   : deployed
REVISION : 2
```

Verify ownership:

```bash
kubectl get deployment banking-app \
  -n banking-dev \
  -o jsonpath='{.metadata.annotations.meta\.helm\.sh/release-name}{"\n"}'
```

Expected:

```text
banking-app
```

---

# 27. Helm Upgrade

After updating `values.yaml` or templates:

```bash
helm upgrade banking-app . \
  -n banking-dev
```

Check:

```bash
helm history banking-app -n banking-dev
```

Then:

```bash
kubectl rollout status \
  deployment/banking-app \
  -n banking-dev
```

---

# 28. Deployment Strategy

Current DEV deployment uses:

```yaml
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxSurge: 0
    maxUnavailable: 1
```

Reason:

The current `t3.micro` workers have very limited pod capacity.

Normal rolling updates can temporarily create an additional pod.

That previously resulted in:

```text
FailedScheduling
0/2 nodes are available: 2 Too many pods
```

Using:

```text
maxSurge: 0
maxUnavailable: 1
```

allows Kubernetes to terminate one old application pod before creating its replacement.

This is a DEV/lab capacity workaround.

Production environments should have sufficient capacity for normal HA rolling deployments.

---

# 29. Application Replica Count

Current DEV value:

```yaml
replicaCount: 1
```

This is intentional because of current node pod capacity.

Production should normally use multiple replicas distributed across worker nodes/AZs together with:

```text
PodDisruptionBudget
Topology spread constraints / anti-affinity
Autoscaling
Adequate node capacity
```

---

# 30. Validate Application Deployment

```bash
kubectl get deployment -n banking-dev
```

Expected:

```text
banking-app   1/1
```

Check rollout:

```bash
kubectl rollout status \
  deployment/banking-app \
  -n banking-dev
```

Expected:

```text
deployment "banking-app" successfully rolled out
```

---

# 31. Validate Pods

```bash
kubectl get pods -n banking-dev -o wide
```

Expected:

```text
READY   STATUS
1/1     Running
```

Check image:

```bash
kubectl get pods -n banking-dev \
  -o jsonpath='{range .items[*]}{.metadata.name}{" -> "}{.spec.containers[0].image}{"\n"}{end}'
```

Confirm the image belongs to:

```text
banking-eks-dev-app
```

and NOT the Project 1 ECR repository.

---

# 32. Validate Pod Health

Check pod details:

```bash
kubectl describe pod <pod-name> -n banking-dev
```

Application probes:

```text
Readiness Probe → HTTP /
Liveness Probe  → HTTP /
Port            → 5000
```

Check logs:

```bash
kubectl logs \
  -n banking-dev \
  deployment/banking-app
```

For live logs:

```bash
kubectl logs \
  -n banking-dev \
  deployment/banking-app \
  -f
```

---

# 33. Validate Service

```bash
kubectl get svc -n banking-dev
```

Expected:

```text
banking-app-service   ClusterIP   ...   80/TCP
```

Inspect:

```bash
kubectl describe svc \
  banking-app-service \
  -n banking-dev
```

Check endpoints:

```bash
kubectl get endpoints \
  banking-app-service \
  -n banking-dev
```

The endpoint must NOT show:

```text
<none>
```

Expected pattern:

```text
10.0.x.x:5000
```

If endpoints are `<none>`, check:

```text
Pod readiness
Service selectors
Pod labels
Container port
Application health
```

---

# 34. Validate Ingress

```bash
kubectl get ingress -n banking-dev
```

Expected:

```text
banking-app-ingress
CLASS: alb
ADDRESS: <AWS-ALB-DNS>
PORTS: 80
```

Detailed inspection:

```bash
kubectl describe ingress \
  banking-app-ingress \
  -n banking-dev
```

---

# 35. Retrieve Application URL

```bash
ALB=$(kubectl get ingress banking-app-ingress \
  -n banking-dev \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

echo "$ALB"
```

Test:

```bash
curl -i "http://$ALB/"
```

Expected:

```text
HTTP/1.1 200 OK
```

Then open:

```text
http://<ALB-DNS>
```

in a browser.

Expected page:

```text
Banking DevOps Platform

Project 2 - Amazon EKS Platform

Successfully deployed using:
- Terraform
- Amazon EKS
- Kubernetes
- Amazon ECR
- AWS Load Balancer Controller
- Application Load Balancer

Environment: DEV
```

---

# 36. End-to-End Health Validation

A new engineer should perform these checks in this exact order.

```text
1. AWS identity
       ↓
2. Terraform state/configuration
       ↓
3. EKS cluster ACTIVE
       ↓
4. Node group ACTIVE
       ↓
5. kubectl connectivity
       ↓
6. Nodes Ready
       ↓
7. aws-node healthy
       ↓
8. CoreDNS healthy
       ↓
9. kube-proxy healthy
       ↓
10. AWS Load Balancer Controller healthy
       ↓
11. Namespace exists
       ↓
12. Helm release deployed
       ↓
13. Deployment available
       ↓
14. Pod Running + Ready
       ↓
15. Service has endpoint
       ↓
16. Ingress has ALB ADDRESS
       ↓
17. ALB target healthy
       ↓
18. curl returns HTTP 200
       ↓
19. Browser displays Project 2 page
```

---

# 37. Quick Health-Check Commands

```bash
aws sts get-caller-identity

aws eks describe-cluster \
  --name banking-eks-dev-cluster \
  --region us-east-1 \
  --query 'cluster.status' \
  --output text

kubectl get nodes

kubectl get pods -A

helm list -n banking-dev

kubectl get deployment -n banking-dev

kubectl get pods -n banking-dev -o wide

kubectl get svc -n banking-dev

kubectl get endpoints -n banking-dev

kubectl get ingress -n banking-dev
```

Application URL:

```bash
ALB=$(kubectl get ingress banking-app-ingress \
  -n banking-dev \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

curl -i "http://$ALB/"
```

---

# 38. Troubleshooting – Pod Pending

Check:

```bash
kubectl get pods -n banking-dev
```

Then:

```bash
kubectl describe pod <pod-name> -n banking-dev
```

Known error encountered:

```text
0/2 nodes are available: 2 Too many pods
```

Check pod capacity:

```bash
kubectl describe nodes | \
grep -E "Name:|pods:|Non-terminated Pods" -A 3
```

Possible solutions:

```text
Increase worker node count
Use appropriately sized worker nodes
Reduce unnecessary workloads
Adjust DEV replica counts
Review CNI/IP/pod density configuration
```

Do not assume CPU or memory is the problem.

Always inspect scheduler Events first.

---

# 39. Troubleshooting – Pod Not Ready

```bash
kubectl describe pod <pod-name> -n banking-dev
```

Check:

```bash
kubectl logs <pod-name> -n banking-dev
```

Check previous container logs if restarted:

```bash
kubectl logs <pod-name> \
  -n banking-dev \
  --previous
```

Validate:

```text
Image
Container port
Readiness probe
Liveness probe
Environment variables
Application startup
```

---

# 40. Troubleshooting – ImagePullBackOff

Check:

```bash
kubectl describe pod <pod-name> -n banking-dev
```

Verify image exists:

```bash
aws ecr describe-images \
  --repository-name banking-eks-dev-app \
  --region us-east-1
```

Check node IAM permissions.

The node role requires ECR pull permissions.

Also confirm the image architecture is compatible with the worker nodes.

Current nodes:

```text
amd64
```

---

# 41. Troubleshooting – Apple Silicon Image

Symptom may include container startup failure or:

```text
exec format error
```

Check local image:

```bash
docker image inspect <image> \
  --format '{{.Os}}/{{.Architecture}}'
```

Build for EKS:

```bash
docker buildx build \
  --platform linux/amd64 \
  -t <ECR-URI>:<NEW-TAG> \
  --push .
```

---

# 42. Troubleshooting – Service Has No Endpoints

```bash
kubectl get endpoints \
  banking-app-service \
  -n banking-dev
```

If:

```text
<none>
```

compare:

```bash
kubectl get pods \
  -n banking-dev \
  --show-labels
```

with:

```bash
kubectl describe svc \
  banking-app-service \
  -n banking-dev
```

The Service selector must match the Pod label:

```text
app=banking-app
```

The pod must also be Ready before it becomes a normal service endpoint.

---

# 43. Troubleshooting – ALB Not Created

Check:

```bash
kubectl describe ingress \
  banking-app-ingress \
  -n banking-dev
```

Check controller:

```bash
kubectl logs \
  -n kube-system \
  deployment/aws-load-balancer-controller
```

Validate:

```text
AWS Load Balancer Controller
IRSA role
OIDC provider
Subnet tags
Ingress class
Ingress annotations
Security groups
IAM policy
```

---

# 44. Troubleshooting – ALB Returns 503

Trace from inside outward:

```text
Pod
 ↓
Readiness
 ↓
Service
 ↓
Endpoints
 ↓
TargetGroupBinding
 ↓
ALB Target Group
 ↓
Ingress
 ↓
ALB
```

Start with:

```bash
kubectl get pods -n banking-dev
```

Then:

```bash
kubectl get endpoints \
  banking-app-service \
  -n banking-dev
```

Then:

```bash
kubectl get targetgroupbinding \
  -n banking-dev
```

Then:

```bash
kubectl describe ingress \
  banking-app-ingress \
  -n banking-dev
```

A previous 503 in this project was caused by the application pod being Pending because node pod capacity was exhausted.

---

# 45. Troubleshooting – AWS Load Balancer Controller

```bash
kubectl get pods -n kube-system | \
grep load-balancer
```

Logs:

```bash
kubectl logs \
  -n kube-system \
  deployment/aws-load-balancer-controller
```

Service account:

```bash
kubectl get sa \
  aws-load-balancer-controller \
  -n kube-system \
  -o yaml
```

Verify IRSA annotation.

---

# 46. TargetGroupBinding

AWS Load Balancer Controller creates TargetGroupBinding resources.

Check:

```bash
kubectl get targetgroupbinding \
  -n banking-dev
```

Describe:

```bash
kubectl describe targetgroupbinding \
  -n banking-dev
```

Current target type:

```text
ip
```

Therefore ALB targets Kubernetes pod IPs rather than worker-node NodePorts.

---

# 47. Helm Troubleshooting

Check:

```bash
helm list -n banking-dev
```

Status:

```bash
helm status banking-app -n banking-dev
```

History:

```bash
helm history banking-app -n banking-dev
```

Render without applying:

```bash
helm template banking-app . -n banking-dev
```

Validate:

```bash
helm lint .
```

---

# 48. Helm Rollback

Check history:

```bash
helm history banking-app -n banking-dev
```

Rollback example:

```bash
helm rollback banking-app <REVISION> \
  -n banking-dev
```

Then:

```bash
kubectl rollout status \
  deployment/banking-app \
  -n banking-dev
```

Always verify the application after rollback.

---

# 49. Kubernetes Rollout Troubleshooting

Check:

```bash
kubectl rollout status \
  deployment/banking-app \
  -n banking-dev
```

History:

```bash
kubectl rollout history \
  deployment/banking-app \
  -n banking-dev
```

Inspect:

```bash
kubectl get rs -n banking-dev
```

If a rollout is stuck:

```bash
kubectl get pods -n banking-dev
kubectl describe pod <pending-or-failing-pod> -n banking-dev
```

Do not repeatedly restart a deployment without understanding the underlying event.

---

# 50. Security Controls

Current controls include:

```text
Private worker subnets
IAM roles
IRSA for AWS Load Balancer Controller
ECR image scanning
ECR encryption
Immutable image tags
Kubernetes health probes
Resource requests and limits
Dedicated Project 2 ECR repository
Terraform-managed infrastructure
```

Future hardening should include:

```text
NetworkPolicy
Pod Security Standards
Secrets Manager / External Secrets
KMS where appropriate
Admission policies
Image vulnerability gates
Least-privilege Kubernetes RBAC
WAF
HTTPS
Central logging
Runtime security
```

---

# 51. HTTP / HTTPS

The current DEV application is exposed over:

```text
HTTP :80
```

Therefore browsers may display:

```text
Not Secure
```

This is expected for the current DEV implementation.

Enterprise production exposure should use:

```text
Route53
   ↓
ACM Certificate
   ↓
HTTPS :443
   ↓
ALB
```

Optionally redirect:

```text
HTTP :80 → HTTPS :443
```

---

# 52. Production Improvements

The current environment demonstrates the platform architecture but is intentionally resource-constrained.

Production should consider:

```text
Multiple worker nodes across AZs
Larger/appropriate instance types
Managed node groups or Karpenter
Cluster Autoscaler/Karpenter
Multiple application replicas
HPA
PodDisruptionBudget
Topology spread constraints
NetworkPolicy
HTTPS/ACM
Route53
AWS WAF
Secrets Manager
External Secrets Operator
Central logging
Prometheus/Grafana
CloudWatch integration
Argo CD HA where required
Backup/DR strategy
```

---

# 53. Argo CD / GitOps – Next Phase

Target architecture:

```text
Developer
   |
   v
Git Push
   |
   v
Git Repository
   |
   v
Argo CD
   |
   v
Helm Chart
   |
   v
Kubernetes
   |
   v
EKS
```

Desired GitOps model:

```text
Git = Source of Truth
```

Argo CD will continuously compare:

```text
Git desired state
        vs
Kubernetes live state
```

and report:

```text
Synced / OutOfSync
Healthy / Degraded
```

Do not document Argo CD as completed until installation, repository integration, synchronization and browser/application validation have been successfully tested.

---

# 54. Monitoring – Future Phase

Planned:

```text
Prometheus
Grafana
```

Before installation, validate worker-node capacity.

The current `t3.micro` lab nodes have limited pod density and should not be treated as production sizing.

---

# 55. New Engineer Onboarding Checklist

Before making any changes:

- [ ] Clone correct repository
- [ ] Verify AWS CLI
- [ ] Verify AWS account `500788673290`
- [ ] Verify region `us-east-1`
- [ ] Verify Terraform version
- [ ] Run `terraform init`
- [ ] Run `terraform validate`
- [ ] Review `terraform plan`
- [ ] Verify EKS cluster is ACTIVE
- [ ] Configure kubeconfig
- [ ] Verify Kubernetes context
- [ ] Verify nodes are Ready
- [ ] Verify kube-system pods
- [ ] Verify AWS Load Balancer Controller
- [ ] Verify ECR repository
- [ ] Verify application image/tag
- [ ] Verify Helm chart
- [ ] Run `helm lint`
- [ ] Run Helm dry-run/template validation
- [ ] Verify Helm release
- [ ] Verify Deployment
- [ ] Verify Pod Ready
- [ ] Verify Service endpoints
- [ ] Verify Ingress ALB address
- [ ] Run curl test
- [ ] Validate application in browser

---

# 56. Operational Golden Path

For an existing healthy environment:

```bash
aws sts get-caller-identity

aws eks update-kubeconfig \
  --region us-east-1 \
  --name banking-eks-dev-cluster

kubectl get nodes

kubectl get pods -A

helm list -n banking-dev

kubectl get deployment,pods,svc,ingress \
  -n banking-dev

kubectl get endpoints \
  banking-app-service \
  -n banking-dev
```

Retrieve URL:

```bash
ALB=$(kubectl get ingress banking-app-ingress \
  -n banking-dev \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

echo "http://$ALB"

curl -i "http://$ALB/"
```

If all checks pass:

```text
AWS Authentication       PASS
EKS Control Plane        PASS
Worker Nodes             PASS
Kubernetes System Pods   PASS
ALB Controller           PASS
Helm Release             PASS
Application Deployment   PASS
Application Pod          PASS
Service Endpoint         PASS
Ingress / ALB            PASS
HTTP 200                 PASS
Browser                  PASS
```

The EKS application is operational.

---

# 57. Incident Troubleshooting Flow

Use this order instead of making random changes:

```text
Browser Failure
      ↓
curl ALB
      ↓
Ingress
      ↓
ALB Controller
      ↓
TargetGroupBinding
      ↓
Service Endpoints
      ↓
Pod Readiness
      ↓
Pod Status
      ↓
Container Logs
      ↓
Kubernetes Events
      ↓
Node Capacity / CNI
      ↓
AWS Infrastructure
```

Useful commands:

```bash
kubectl get events -A \
  --sort-by='.lastTimestamp'

kubectl get pods -A -o wide

kubectl describe pod <pod> -n <namespace>

kubectl logs <pod> -n <namespace>

kubectl get endpoints -n banking-dev

kubectl describe ingress banking-app-ingress \
  -n banking-dev

kubectl logs \
  -n kube-system \
  deployment/aws-load-balancer-controller
```

---

# 58. Known Issues / Lessons Learned

## Issue 1 – EKS CNI

Symptom:

```text
CNI failed to assign IP
```

Resolution included ensuring the node IAM role had:

```text
AmazonEKS_CNI_Policy
```

---

## Issue 2 – Limited Pod Capacity

Symptom:

```text
FailedScheduling
0/2 nodes are available: 2 Too many pods
```

Observed `t3.micro` capacity:

```text
4 pods per node
```

Mitigation in DEV:

```text
Application replicaCount = 1
AWS Load Balancer Controller replicas = 1
RollingUpdate maxSurge = 0
```

Long-term solution:

```text
Increase appropriate worker capacity / pod density.
```

---

## Issue 3 – ALB 503

ALB existed but returned:

```text
503
```

Root cause:

```text
Application pod Pending
        ↓
Service had no healthy endpoint
        ↓
ALB target unavailable
```

Resolution:

```text
Fix Kubernetes scheduling capacity
        ↓
Pod Running/Ready
        ↓
Service endpoint created
        ↓
ALB target healthy
        ↓
Application reachable
```

---

## Issue 4 – Project 1 Image Reused Initially

The initial EKS deployment temporarily used:

```text
banking-devops-dev-app
```

which belonged to Project 1.

This caused the browser to display Project 1 content.

Resolution:

```text
Create project2-eks/app
        ↓
Create dedicated ECR
banking-eks-dev-app
        ↓
Build Project 2 image
        ↓
Deploy Project 2 image to EKS
```

Project separation is now maintained.

---

## Issue 5 – Terraform vs eksctl Drift

OIDC association performed with `eksctl` added:

```text
alpha.eksctl.io/cluster-oidc-enabled=true
```

Terraform detected this external change.

Do not blindly remove externally created configuration without understanding its impact.

---

# 59. Definition of Done

Project 2 base platform is considered operational when:

```text
Terraform infrastructure validated
EKS cluster ACTIVE
Managed node group ACTIVE
Nodes Ready
EKS networking healthy
AWS Load Balancer Controller healthy
Dedicated ECR available
Project 2 image available
Helm chart validated
Helm release deployed
Application pod Ready
Service endpoint populated
Ingress has ALB address
ALB target healthy
HTTP request returns success
Project 2 page opens in browser
```

GitOps, observability and additional security controls should be marked complete only after their respective implementation and validation.

---

# 60. Final Architecture

```text
                     AWS
                      |
              +-------+-------+
              |               |
            Public          Private
            Subnets         Subnets
              |               |
              |               v
              |          EKS Worker Nodes
              |               |
              |         +-----+-----+
              |         |           |
              |      System      Banking App
              |       Pods          Pod
              |                       |
              |                       v
Internet ---> ALB <--- Ingress <--- Service
              ^
              |
     AWS Load Balancer
        Controller
              ^
              |
             IRSA
              |
             IAM


Developer
   |
   +---- Terraform ----> AWS Infrastructure
   |
   +---- Docker -------> Amazon ECR
   |
   +---- Helm ---------> Kubernetes
   |
   +---- Git ----------> Argo CD [Next Phase]
```

---

# 61. Current Project Status

```text
[COMPLETED] Terraform remote state integration
[COMPLETED] Shared VPC integration
[COMPLETED] Amazon EKS control plane
[COMPLETED] EKS managed node group
[COMPLETED] Kubernetes connectivity
[COMPLETED] EKS CNI troubleshooting
[COMPLETED] Dedicated Project 2 ECR
[COMPLETED] Project 2 Docker image
[COMPLETED] Kubernetes Deployment
[COMPLETED] Kubernetes Service
[COMPLETED] AWS Load Balancer Controller
[COMPLETED] Kubernetes Ingress
[COMPLETED] Internet-facing ALB
[COMPLETED] Browser application validation
[COMPLETED] Helm chart
[COMPLETED] Helm ownership/adoption
[COMPLETED] Helm upgrade validation

[IN PROGRESS] Worker capacity expansion

[NEXT] Argo CD / GitOps
[NEXT] HPA / PDB
[NEXT] NetworkPolicy
[NEXT] Secrets integration
[NEXT] Prometheus / Grafana
[NEXT] DevSecOps / GitOps pipeline
```

---

# 62. Important Rule

Before changing this platform:

```text
Observe
   ↓
Validate
   ↓
Plan
   ↓
Review
   ↓
Change
   ↓
Verify
```

Never troubleshoot an EKS production-style environment by making multiple unverified changes simultaneously.

Every infrastructure change should be reproducible, reviewed and validated.
