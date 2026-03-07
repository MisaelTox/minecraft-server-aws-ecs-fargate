# AWS Serverless Minecraft Infrastructure

![Terraform CI/CD](https://github.com/MisaelTox/minecraft-server-aws-ecs-fargate/actions/workflows/terraform.yml/badge.svg)
![AWS](https://img.shields.io/badge/AWS-ECS%20Fargate-orange?logo=amazon-aws)
![Terraform](https://img.shields.io/badge/IaC-Terraform-purple?logo=terraform)

This project deploys a **Minecraft: Java Edition** server on **AWS ECS Fargate** using **Terraform**, with a fully automated CI/CD pipeline via **GitHub Actions**.

---

## 🏗️ Architecture

| Component | Technology |
|-----------|-----------|
| Compute | AWS ECS Fargate (1vCPU / 2GB RAM) |
| Storage | Amazon EFS (persistent world data) |
| Networking | Custom VPC, public subnets, Internet Gateway |
| Logging | CloudWatch Logs |
| IaC | Terraform |
| CI/CD | GitHub Actions |

---

## 🔄 CI/CD Pipeline

Every push to `main` automatically triggers:
```
Push to main
      ↓
✅ terraform fmt     → format validation
✅ terraform validate → syntax check  
✅ terraform plan    → AWS impact preview
      ↓
⏸️  Manual approval gate (production environment)
      ↓
🚀  terraform apply  → deploy to AWS
```

AWS credentials are stored as **GitHub Secrets** — never hardcoded.

---

## 🚀 Deployment Instructions

### Prerequisites
- Terraform installed
- AWS CLI configured

### Steps
```bash
terraform init && terraform plan
terraform apply -auto-approve
```

Connect via Minecraft Java Edition using the Task Public IP from the AWS Console.

---

## 📝 Lessons Learned

- **CI/CD with GitHub Actions** — automated IaC validation and deployment pipeline with manual approval gate for production
- **Container Storage** — mounting EFS volumes into ECS tasks to solve stateless container persistence
- **Fargate Performance** — tuning CPU/Memory allocation for server stability vs cost
- **Security Hardening** — Least Privilege security groups and IAM roles; AWS credentials managed via encrypted secrets

---

*Fork of the original work by [Antoine CICHOWICZ](https://github.com/czantoine), extended with CI/CD automation.*
