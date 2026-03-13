# AWS Serverless Minecraft Infrastructure

![Terraform CI/CD](https://github.com/MisaelTox/minecraft-server-aws-ecs-fargate/actions/workflows/terraform.yml/badge.svg)
![AWS](https://img.shields.io/badge/AWS-ECS%20Fargate-orange?logo=amazon-aws)
![Terraform](https://img.shields.io/badge/IaC-Terraform-purple?logo=terraform)
![Cost](https://img.shields.io/badge/Cost-~%2412%2Fmonth-brightgreen)

This project deploys a **Minecraft: Java Edition** server on **AWS ECS Fargate** using **Terraform**, with a fully automated CI/CD pipeline via **GitHub Actions**.

---

## 🏗️ Architecture

![AWS Architecture Diagram](./img/minecraft-arc.drawio.png)


| Component | Technology |
|-----------|-----------|
| Compute | AWS ECS Fargate SPOT (1vCPU / 2GB RAM) |
| Storage | Amazon EFS (persistent world data) |
| Networking | Custom VPC, public subnet, Internet Gateway, Security Group |
| Logging | Amazon CloudWatch Logs |
| IaC | Terraform |
| CI/CD | GitHub Actions |

---

## 💡 Technical Decisions

### Why Fargate SPOT instead of EC2 or Fargate on-demand?

A standard EC2 instance requires managing OS updates, SSH hardening, and manual scaling. Fargate eliminates that overhead entirely — no servers to patch, no AMIs to maintain.

Within Fargate, I chose **SPOT capacity** specifically because a Minecraft server is an interruptible workload: players can reconnect in seconds if a task gets replaced, and the world data is safe on EFS regardless. This makes it a perfect fit for SPOT, which uses AWS's spare compute capacity at a steep discount.

| Option | Cost/month (24/7) | Notes |
|--------|------------------|-------|
| EC2 t3.small on-demand | ~$15–18 | Server management overhead |
| Fargate on-demand | ~$36 | No management, but expensive |
| **Fargate SPOT** ✅ | **~$11** | **~69% cheaper than on-demand** |

### Why EFS instead of EBS?

EBS volumes are tied to a single Availability Zone. If Fargate replaces the task in a different AZ (which it does freely with SPOT), the EBS volume wouldn't be accessible — you'd lose the world.

**EFS is a network file system**: it's accessible from any AZ, mounts automatically into the new Fargate task, and the Minecraft world survives every restart or task replacement transparently. It's the only storage option that works correctly with stateless Fargate containers across AZs.

### Why a custom VPC instead of the default?

The default AWS VPC has broad network permissions that don't follow least-privilege principles. A custom VPC lets me define exactly which subnets exist, control routing explicitly, and isolate resources cleanly — which matters for any production-grade infrastructure.

---

## 💰 Cost Breakdown

> Estimated for `eu-north-1` (Stockholm), server running 24/7. Costs scale down significantly if you stop the task when not in use.

| Service | Usage | Monthly Cost |
|---------|-------|-------------|
| ECS Fargate SPOT | 1 vCPU + 2GB RAM, 730h | ~$13.07 |
| Amazon EFS | ~2 GB world data | ~$0.64 |
| CloudWatch Logs | Low volume | ~$0.12 |
| VPC / Networking | Data transfer | ~$0.60 |
| **Total** | | **~$14.43/month** |

**vs Fargate on-demand:** ~$43.53/month → **~67% savings with SPOT**

> 💡 Tip: Stop the ECS task when the server isn't in use. At ~$0.017/hour, running it only 4h/day reduces the total cost to ~$2.91/month.

---

## 🔄 CI/CD Pipeline

Every push to `main` automatically triggers:

```
Push to main
      ↓
✅ terraform fmt      → format validation
✅ terraform validate → syntax check
✅ terraform plan     → AWS impact preview
      ↓
⏸️  Manual approval gate (production environment)
      ↓
🚀  terraform apply   → deploy to AWS
```

AWS credentials are stored as **GitHub Secrets** — never hardcoded.

---

## 🚀 Deployment Instructions

### Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.0 installed
- [AWS CLI](https://aws.amazon.com/cli/) configured with a profile that has ECS, EFS, VPC, and IAM permissions
- An S3 bucket for Terraform remote state (update `backend.tf` with your bucket name)

### 1. Clone and configure

```bash
git clone https://github.com/MisaelTox/minecraft-server-aws-ecs-fargate.git
cd minecraft-server-aws-ecs-fargate
```

Edit `terraform.tfvars` (or create it) with your values:

```hcl
aws_region   = "us-east-1"
server_name  = "my-minecraft-server"
```

### 2. Initialize and deploy

```bash
terraform init     # download providers and configure remote state
terraform plan     # preview what AWS resources will be created
terraform apply    # deploy (~3–5 minutes)
```

### 3. Connect to the server

After `apply` completes:

1. Go to **AWS Console → ECS → Clusters → Tasks**
2. Click the running task → copy the **Public IP**
3. Open Minecraft Java Edition → Multiplayer → Add Server → paste the IP with port `25565`

### 4. Tear down

```bash
terraform destroy  # removes all AWS resources and stops billing
```

> ⚠️ The EFS volume (world data) is retained by default on destroy. To delete it too, set `deletion_protection = false` in `efs.tf` before running destroy.

---

## 📝 Lessons Learned

- **CI/CD with GitHub Actions** — automated IaC validation and deployment pipeline with manual approval gate for production
- **Stateful containers** — mounting EFS into Fargate tasks solves the classic stateless container problem without sacrificing portability across AZs
- **Cost optimization** — matching workload interruptibility (Minecraft) to the right pricing model (SPOT) achieves ~69% savings with no impact on the player experience
- **Security hardening** — least-privilege Security Groups (only TCP :25565 inbound) and scoped IAM Task Roles; AWS credentials managed via encrypted GitHub Secrets

---

*Fork of the original work by [Antoine CICHOWICZ](https://github.com/czantoine), extended with CI/CD automation, cost analysis, and architectural documentation.*
