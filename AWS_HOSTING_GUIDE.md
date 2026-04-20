# 🚀 Servio — AWS Free Tier Hosting Guide

> Complete step-by-step guide for deploying the Servio web application on AWS Free Tier with a CI/CD pipeline using GitHub Actions.

---

## Table of Contents

1. [Architecture Overview](#1-architecture-overview)
2. [Prerequisites](#2-prerequisites)
3. [AWS Account Setup](#3-aws-account-setup)
4. [Create an S3 Bucket for Frontend](#4-create-an-s3-bucket-for-frontend)
5. [Set Up CloudFront CDN](#5-set-up-cloudfront-cdn)
6. [Create ECR Repository for Backend](#6-create-ecr-repository-for-backend)
7. [Launch EC2 Instance](#7-launch-ec2-instance)
8. [Install Docker on EC2](#8-install-docker-on-ec2)
9. [Configure the EC2 Instance](#9-configure-the-ec2-instance)
10. [First Manual Deploy](#10-first-manual-deploy)
11. [Set Up CI/CD Pipeline](#11-set-up-cicd-pipeline)
12. [HTTPS & Custom Domain (Optional)](#12-https--custom-domain-optional)
13. [Monitoring & Logs](#13-monitoring--logs)
14. [Cost Optimization](#14-cost-optimization)
15. [Troubleshooting](#15-troubleshooting)

---

## 1. Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                         USERS (Browser)                        │
└──────────┬──────────────────────────┬──────────────────────────┘
           │                          │
           │ Static Assets            │ API Requests
           │ (HTML, JS, CSS)          │ (REST + WebSocket)
           ▼                          ▼
┌──────────────────────┐   ┌──────────────────────────┐
│   Amazon CloudFront  │   │   EC2 t2.micro           │
│   (CDN)              │   │   ┌──────────────────┐   │
│         │            │   │   │ Docker           │   │
│         ▼            │   │   │  ┌────────────┐  │   │
│   ┌──────────────┐   │   │   │  │ Spring Boot│  │   │
│   │  S3 Bucket   │   │   │   │  │ Backend    │  │   │
│   │  (Frontend)  │   │   │   │  │ :3001      │  │   │
│   └──────────────┘   │   │   │  └────────────┘  │   │
└──────────────────────┘   │   └──────────────────┘   │
                           └──────────┬───────────────┘
                                      │
                                      ▼
                           ┌──────────────────────┐
                           │   Supabase           │
                           │   (PostgreSQL + Auth) │
                           └──────────────────────┘
```

**Why this architecture?**

| Component | Service | Free Tier Limit | Why |
|---|---|---|---|
| Frontend | S3 + CloudFront | 5 GB + 1 TB transfer | Static site = no server needed, globally cached |
| Backend | EC2 t2.micro | 750 hrs/month (12 months) | Spring Boot needs a JVM runtime |
| Backend Image | ECR | 500 MB storage | Docker image registry |
| Database | Supabase (external) | Free plan | Already using Supabase, no AWS cost |

---

## 2. Prerequisites

- **AWS Account** — New account with Free Tier eligibility ([sign up](https://aws.amazon.com/free/))
- **GitHub Account** — With the Servio repo (public)
- **AWS CLI** — Installed locally ([install guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html))
- **Git** — Installed locally
- **SSH Key Pair** — You'll create one in AWS

---

## 3. AWS Account Setup

### 3.1 Create AWS Account
1. Go to https://aws.amazon.com/free/
2. Sign up with your email
3. Add a payment method (you won't be charged if you stay within Free Tier)
4. Select the **Basic (Free)** support plan

### 3.2 Set Up Billing Alerts ⚠️
> This is critical to avoid unexpected charges.

1. Go to **Billing Dashboard** → **Billing preferences**
2. Enable **Receive Free Tier Usage Alerts**
3. Go to **CloudWatch** → **Alarms** → **Create Alarm**
4. Select metric: `Billing` → `Total Estimated Charge`
5. Set threshold: `> $1.00`
6. Add your email as a notification target

### 3.3 Create an IAM User for Deployment

1. Go to **IAM** → **Users** → **Create user**
2. Username: `servio-deployer`
3. Attach policies:
   - `AmazonEC2FullAccess`
   - `AmazonS3FullAccess`
   - `AmazonEC2ContainerRegistryFullAccess`
   - `CloudFrontFullAccess`
4. Go to **Security credentials** → **Create access key**
5. Select **Command Line Interface (CLI)**
6. Save the **Access Key ID** and **Secret Access Key** — you'll need these for GitHub Secrets

### 3.4 Configure AWS CLI Locally
```bash
aws configure
# AWS Access Key ID: <your-access-key>
# AWS Secret Access Key: <your-secret-key>
# Default region name: ap-south-1
# Default output format: json
```

---

## 4. Create an S3 Bucket for Frontend

### 4.1 Create the Bucket
```bash
aws s3 mb s3://servio-frontend --region ap-south-1
```

### 4.2 Enable Static Website Hosting
```bash
aws s3 website s3://servio-frontend \
  --index-document index.html \
  --error-document index.html
```

> The error document is set to `index.html` to support React Router's client-side routing.

### 4.3 Set Bucket Policy for Public Read Access
Create a file called `bucket-policy.json`:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PublicReadGetObject",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::servio-frontend/*"
    }
  ]
}
```

Apply the policy:
```bash
# First, disable Block Public Access
aws s3api put-public-access-block \
  --bucket servio-frontend \
  --public-access-block-configuration \
  "BlockPublicAcls=false,IgnorePublicAcls=false,BlockPublicPolicy=false,RestrictPublicBuckets=false"

# Then apply the bucket policy
aws s3api put-bucket-policy \
  --bucket servio-frontend \
  --policy file://bucket-policy.json
```

### 4.4 Test: Upload Frontend Build Manually
```bash
cd frontend
npm ci && npm run build
aws s3 sync dist/ s3://servio-frontend --delete
```

The site is now accessible at:
```
http://servio-frontend.s3-website.ap-south-1.amazonaws.com
```

---

## 5. Set Up CloudFront CDN

CloudFront provides HTTPS, caching, and global distribution — all within Free Tier.

### 5.1 Create CloudFront Distribution

1. Go to **CloudFront** → **Create distribution**
2. **Origin domain**: Select your S3 bucket (`servio-frontend.s3.ap-south-1.amazonaws.com`)
3. **Origin access**: Select **Origin access control settings (recommended)**
4. Click **Create new OAC** → Create
5. **Default cache behavior**:
   - Viewer protocol policy: **Redirect HTTP to HTTPS**
   - Allowed HTTP methods: **GET, HEAD**
   - Cache policy: **CachingOptimized**
6. **Settings**:
   - Default root object: `index.html`
7. Click **Create distribution**

### 5.2 Configure Custom Error Responses (SPA Support)

1. Go to your distribution → **Error pages** tab
2. Create custom error response:
   - HTTP error code: `403`
   - Customize error response: **Yes**
   - Response page path: `/index.html`
   - HTTP response code: `200`
3. Repeat for error code `404`

> This ensures React Router works correctly — all routes serve `index.html`.

### 5.3 Update S3 Bucket Policy for CloudFront OAC

CloudFront will provide you with a policy statement. Update your bucket policy:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowCloudFrontServicePrincipal",
      "Effect": "Allow",
      "Principal": {
        "Service": "cloudfront.amazonaws.com"
      },
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::servio-frontend/*",
      "Condition": {
        "StringEquals": {
          "AWS:SourceArn": "arn:aws:cloudfront::<YOUR_ACCOUNT_ID>:distribution/<YOUR_DISTRIBUTION_ID>"
        }
      }
    }
  ]
}
```

### 5.4 Note your CloudFront URL

After deployment (takes ~5 minutes), your frontend is accessible at:
```
https://d1234567890.cloudfront.net
```

Save the **Distribution ID** — you'll need it for CI/CD.

---

## 6. Create ECR Repository for Backend

```bash
aws ecr create-repository \
  --repository-name servio-backend \
  --region ap-south-1 \
  --image-scanning-configuration scanOnPush=true
```

Note the repository URI (e.g., `123456789012.dkr.ecr.ap-south-1.amazonaws.com/servio-backend`).

### Set Up Lifecycle Policy (to stay within 500 MB free limit)
```bash
aws ecr put-lifecycle-policy \
  --repository-name servio-backend \
  --lifecycle-policy-text '{
    "rules": [
      {
        "rulePriority": 1,
        "description": "Keep last 3 images",
        "selection": {
          "tagStatus": "any",
          "countType": "imageCountMoreThan",
          "countNumber": 3
        },
        "action": {
          "type": "expire"
        }
      }
    ]
  }'
```

---

## 7. Launch EC2 Instance

### 7.1 Create Key Pair
```bash
aws ec2 create-key-pair \
  --key-name servio-key \
  --query "KeyMaterial" \
  --output text > servio-key.pem

chmod 400 servio-key.pem
```

### 7.2 Create Security Group
```bash
# Create security group
aws ec2 create-security-group \
  --group-name servio-sg \
  --description "Servio Backend Security Group"

# Allow SSH (port 22)
aws ec2 authorize-security-group-ingress \
  --group-name servio-sg \
  --protocol tcp \
  --port 22 \
  --cidr 0.0.0.0/0

# Allow Backend API (port 3001)
aws ec2 authorize-security-group-ingress \
  --group-name servio-sg \
  --protocol tcp \
  --port 3001 \
  --cidr 0.0.0.0/0

# Allow HTTPS (port 443) — for ECR pulls
aws ec2 authorize-security-group-ingress \
  --group-name servio-sg \
  --protocol tcp \
  --port 443 \
  --cidr 0.0.0.0/0
```

### 7.3 Launch the Instance

```bash
aws ec2 run-instances \
  --image-id ami-0f58b397bc5c1f2e8 \
  --instance-type t2.micro \
  --key-name servio-key \
  --security-groups servio-sg \
  --block-device-mappings '[{"DeviceName":"/dev/xvda","Ebs":{"VolumeSize":20,"VolumeType":"gp3"}}]' \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=servio-backend}]' \
  --count 1
```

> **Note**: The AMI ID `ami-0f58b397bc5c1f2e8` is for Amazon Linux 2023 in `ap-south-1`. If you're using a different region, find the correct AMI ID in the AWS Console under EC2 → Launch Instance.

### 7.4 Allocate Elastic IP (Free if associated)
```bash
# Allocate
ALLOC_ID=$(aws ec2 allocate-address --query "AllocationId" --output text)

# Get instance ID
INSTANCE_ID=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=servio-backend" "Name=instance-state-name,Values=running" \
  --query "Reservations[0].Instances[0].InstanceId" \
  --output text)

# Associate
aws ec2 associate-address --instance-id $INSTANCE_ID --allocation-id $ALLOC_ID

# Show the public IP
aws ec2 describe-addresses --allocation-ids $ALLOC_ID --query "Addresses[0].PublicIp" --output text
```

Save this IP address — it's your backend URL: `http://<ELASTIC_IP>:3001`

---

## 8. Install Docker on EC2

### 8.1 SSH into the Instance
```bash
ssh -i servio-key.pem ec2-user@<ELASTIC_IP>
```

### 8.2 Install Docker & Docker Compose
```bash
# Update system
sudo dnf update -y

# Install Docker
sudo dnf install -y docker

# Start and enable Docker
sudo systemctl start docker
sudo systemctl enable docker

# Add ec2-user to docker group (avoids needing sudo)
sudo usermod -aG docker ec2-user

# Install Docker Compose plugin
sudo mkdir -p /usr/local/lib/docker/cli-plugins
sudo curl -SL https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64 \
  -o /usr/local/lib/docker/cli-plugins/docker-compose
sudo chmod +x /usr/local/lib/docker/cli-plugins/docker-compose

# Install AWS CLI (already included in Amazon Linux 2023)
aws --version

# Log out and back in for group changes
exit
```

```bash
# SSH back in
ssh -i servio-key.pem ec2-user@<ELASTIC_IP>

# Verify
docker --version
docker compose version
```

---

## 9. Configure the EC2 Instance

### 9.1 Enable Swap Space (Critical for t2.micro!)

The t2.micro only has 1 GB RAM. Swap prevents out-of-memory kills.

```bash
# Create 1 GB swap file
sudo dd if=/dev/zero of=/swapfile bs=1M count=1024
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# Make permanent
echo '/swapfile swap swap defaults 0 0' | sudo tee -a /etc/fstab

# Verify
free -h
```

### 9.2 Configure AWS CLI for ECR Access

```bash
# Configure AWS CLI on the EC2 instance
aws configure
# Enter the same Access Key ID and Secret Access Key
# Region: ap-south-1
# Output: json
```

### 9.3 Set Up the Application Directory

```bash
mkdir -p /home/ec2-user/servio
cd /home/ec2-user/servio
```

### 9.4 Create the `.env` File

```bash
cat > .env << 'EOF'
# ---- Supabase Database ----
DB_HOST=aws-0-ap-south-1.pooler.supabase.com
DB_PORT=6543
DB_USER=postgres.your-project-ref
DB_PASSWORD=your-db-password
DB_NAME=postgres

# ---- Supabase Auth ----
SUPABASE_URL=https://your-project-ref.supabase.co
SUPABASE_ANON_KEY=your-supabase-anon-key
SUPABASE_JWT_SECRET=your-supabase-jwt-secret

# ---- JWT ----
JWT_SECRET=your-production-jwt-secret
JWT_EXPIRATION=604800000

# ---- CORS ----
CORS_ALLOWED_ORIGINS=https://d1234567890.cloudfront.net,http://localhost
FRONTEND_URL=https://d1234567890.cloudfront.net

# ---- PayHere ----
PAYHERE_MERCHANT_ID=1219999
PAYHERE_MERCHANT_SECRET=your-merchant-secret
PAYHERE_SANDBOX=false

# ---- AWS (for docker-compose.prod.yml) ----
AWS_ACCOUNT_ID=123456789012
AWS_REGION=ap-south-1
EOF
```

> ⚠️ Replace all placeholder values with your actual credentials.

### 9.5 Copy the Production Compose File

```bash
# From your local machine:
scp -i servio-key.pem docker-compose.prod.yml ec2-user@<ELASTIC_IP>:/home/ec2-user/servio/
```

---

## 10. First Manual Deploy

### 10.1 Build and Push Backend Image (from your local machine)

```bash
# Login to ECR
aws ecr get-login-password --region ap-south-1 | \
  docker login --username AWS --password-stdin \
  <AWS_ACCOUNT_ID>.dkr.ecr.ap-south-1.amazonaws.com

# Build the backend image
docker build -t servio-backend ./backend

# Tag it
docker tag servio-backend:latest \
  <AWS_ACCOUNT_ID>.dkr.ecr.ap-south-1.amazonaws.com/servio-backend:latest

# Push to ECR
docker push <AWS_ACCOUNT_ID>.dkr.ecr.ap-south-1.amazonaws.com/servio-backend:latest
```

### 10.2 Deploy on EC2

```bash
# SSH into EC2
ssh -i servio-key.pem ec2-user@<ELASTIC_IP>

cd /home/ec2-user/servio

# Login to ECR
aws ecr get-login-password --region ap-south-1 | \
  docker login --username AWS --password-stdin \
  <AWS_ACCOUNT_ID>.dkr.ecr.ap-south-1.amazonaws.com

# Pull and start
docker compose -f docker-compose.prod.yml pull
docker compose -f docker-compose.prod.yml up -d

# Check status
docker compose -f docker-compose.prod.yml ps
docker compose -f docker-compose.prod.yml logs -f backend
```

### 10.3 Deploy Frontend to S3

```bash
# From your local machine
cd frontend
VITE_API_URL=http://<ELASTIC_IP>:3001/api \
VITE_SUPABASE_URL=https://your-ref.supabase.co \
VITE_SUPABASE_ANON_KEY=your-key \
  npm run build

aws s3 sync dist/ s3://servio-frontend --delete
```

### 10.4 Verify

- **Backend**: Visit `http://<ELASTIC_IP>:3001/api/services`
- **Frontend**: Visit your CloudFront URL `https://d1234567890.cloudfront.net`

---

## 11. Set Up CI/CD Pipeline

The CI/CD pipeline uses **GitHub Actions** to automatically deploy on every push to `main`.

### 11.1 Architecture

```
┌────────────┐     push to main     ┌────────────────────┐
│ Developer  │ ──────────────────►  │ GitHub Actions     │
│ (git push) │                      │                    │
└────────────┘                      │  ┌──────────────┐  │
                                    │  │ Job 1:       │  │
                                    │  │ Build React  │──┼──► S3 Bucket
                                    │  │ Deploy to S3 │  │    (+ CloudFront invalidation)
                                    │  └──────────────┘  │
                                    │                    │
                                    │  ┌──────────────┐  │
                                    │  │ Job 2:       │  │
                                    │  │ Build Docker │──┼──► ECR  ──► EC2 (SSH deploy)
                                    │  │ Push to ECR  │  │
                                    │  └──────────────┘  │
                                    └────────────────────┘
```

### 11.2 Add GitHub Secrets

Go to your GitHub repo → **Settings** → **Secrets and variables** → **Actions** → **New repository secret**

Add the following secrets:

| Secret Name | Value | Description |
|---|---|---|
| `AWS_ACCESS_KEY_ID` | `AKIA...` | IAM user access key |
| `AWS_SECRET_ACCESS_KEY` | `wJal...` | IAM user secret |
| `AWS_ACCOUNT_ID` | `123456789012` | Your 12-digit AWS account ID |
| `EC2_HOST` | `1.2.3.4` | Your EC2 Elastic IP address |
| `EC2_SSH_KEY` | `-----BEGIN RSA PRIVATE...` | Contents of `servio-key.pem` |
| `SUPABASE_URL` | `https://xxx.supabase.co` | Supabase project URL |
| `SUPABASE_ANON_KEY` | `eyJ...` | Supabase anonymous key |
| `VITE_API_URL` | `http://<ELASTIC_IP>:3001/api` | Backend API URL for frontend |
| `CLOUDFRONT_DISTRIBUTION_ID` | `E1234567890` | CloudFront distribution ID |

### 11.3 Workflow File

The workflow file is already created at `.github/workflows/deploy.yml`. It runs two parallel jobs:

1. **deploy-frontend**: Builds the React app with Vite, syncs to S3, invalidates CloudFront cache
2. **deploy-backend**: Builds the Docker image, pushes to ECR, SSHs into EC2 to pull and restart

### 11.4 Trigger a Deploy

```bash
git add .
git commit -m "feat: add CI/CD pipeline for AWS deployment"
git push origin main
```

Monitor the pipeline at: `https://github.com/<your-username>/Servio/actions`

---

## 12. HTTPS & Custom Domain (Optional)

Since this is a university project without a domain name, you can use:

- **Frontend**: CloudFront provides HTTPS automatically at `https://d1234567890.cloudfront.net`
- **Backend**: For HTTPS on EC2 without a domain, you have a few options:

### Option A: Use HTTP (Simplest — Recommended for University Project)
- Frontend (CloudFront) → HTTPS ✅
- Backend API calls → HTTP (port 3001)
- Update CORS to allow your CloudFront HTTPS origin

### Option B: Free Domain + Let's Encrypt (If you want full HTTPS)
1. Get a free domain from [Freenom](https://www.freenom.com/) or use your university's subdomain
2. Install Certbot on EC2:
```bash
sudo dnf install -y certbot
sudo certbot certonly --standalone -d api.servio.example.com
```

For a university project, **Option A is perfectly fine**.

---

## 13. Monitoring & Logs

### View Container Logs on EC2
```bash
ssh -i servio-key.pem ec2-user@<ELASTIC_IP>

# Live logs
docker compose -f docker-compose.prod.yml logs -f backend

# Last 100 lines
docker compose -f docker-compose.prod.yml logs --tail 100 backend

# Check resource usage
docker stats
```

### EC2 Instance Monitoring
- Go to **EC2** → Select your instance → **Monitoring** tab
- View CPU, network, and disk metrics (free with EC2)

### Set Up a Simple Health Check Script
```bash
# On EC2, create a cron job to auto-restart if backend goes down
cat > /home/ec2-user/health-check.sh << 'SCRIPT'
#!/bin/bash
if ! curl -sf http://localhost:3001/api/services > /dev/null 2>&1; then
  echo "$(date): Backend is down, restarting..." >> /home/ec2-user/health-check.log
  cd /home/ec2-user/servio
  docker compose -f docker-compose.prod.yml restart backend
fi
SCRIPT

chmod +x /home/ec2-user/health-check.sh

# Run every 5 minutes
(crontab -l 2>/dev/null; echo "*/5 * * * * /home/ec2-user/health-check.sh") | crontab -
```

---

## 14. Cost Optimization

### Free Tier Limits (12 months)

| Service | Free Limit | Your Usage | Status |
|---|---|---|---|
| EC2 t2.micro | 750 hrs/month | ~730 hrs (24/7) | ✅ Within limit |
| EBS (gp3) | 30 GB | 20 GB | ✅ Within limit |
| S3 | 5 GB storage | ~50 MB (frontend) | ✅ Within limit |
| S3 Requests | 20K GET, 2K PUT | Varies | ✅ Likely within limit |
| CloudFront | 1 TB transfer | Low traffic | ✅ Within limit |
| ECR | 500 MB | ~300 MB (3 images max) | ✅ Within limit |
| Data Transfer | 100 GB out | Low traffic | ✅ Within limit |
| Elastic IP | Free (if associated) | 1 IP, associated | ✅ Free |

### Tips to Stay Within Free Tier

1. **Never run more than 1 EC2 instance** — 750 hrs is for all t2.micro instances combined
2. **Set ECR lifecycle policy** (already done) to keep only 3 images
3. **Don't enable CloudWatch Detailed Monitoring** — basic monitoring is free
4. **Stop the EC2 instance when not needed** (e.g., during semester breaks):
   ```bash
   # Stop
   aws ec2 stop-instances --instance-ids <INSTANCE_ID>
   # Start
   aws ec2 start-instances --instance-ids <INSTANCE_ID>
   ```
5. **Release the Elastic IP if the instance is stopped** — an unassociated Elastic IP incurs charges

### After Free Tier Expires (12 months)

Estimated monthly cost for this architecture:
- EC2 t2.micro: ~$8.50/month
- EBS 20 GB: ~$1.60/month  
- S3 + CloudFront: ~$0.50/month
- ECR: ~$0.10/month
- **Total: ~$10.70/month**

---

## 15. Troubleshooting

### Backend won't start (Out of Memory)
```bash
# Check if swap is enabled
free -h

# If no swap, enable it (see Section 9.1)

# Check container memory usage
docker stats --no-stream

# Reduce JVM memory if needed — edit docker-compose.prod.yml
# Or set env var: JAVA_OPTS=-Xmx256m
```

### CORS Errors in Browser
```bash
# Ensure CORS_ALLOWED_ORIGINS in .env includes your CloudFront URL
CORS_ALLOWED_ORIGINS=https://d1234567890.cloudfront.net

# Restart backend
cd /home/ec2-user/servio
docker compose -f docker-compose.prod.yml restart backend
```

### ECR Login Failed
```bash
# Re-authenticate
aws ecr get-login-password --region ap-south-1 | \
  docker login --username AWS --password-stdin \
  <AWS_ACCOUNT_ID>.dkr.ecr.ap-south-1.amazonaws.com
```

### GitHub Actions Failing
1. Check **Actions** tab on GitHub for error logs
2. Common issues:
   - **SSH connection refused**: Ensure EC2 security group allows port 22
   - **ECR push denied**: Check IAM permissions
   - **S3 access denied**: Check IAM policy includes `AmazonS3FullAccess`

### Container keeps restarting
```bash
# Check logs for the error
docker compose -f docker-compose.prod.yml logs backend

# Common causes:
# - Wrong DB credentials in .env
# - Supabase connection blocked (check Supabase dashboard → Database → Connection Pooling)
# - Port 3001 already in use
```

### Frontend shows blank page
1. Check browser console for errors
2. Ensure `VITE_API_URL` was set correctly during the build
3. Verify CloudFront custom error pages are configured (Section 5.2)
4. Check S3 bucket contents: `aws s3 ls s3://servio-frontend/`

### Disk Space Running Low
```bash
# Clean up Docker
docker system prune -af
docker volume prune -f

# Check disk usage
df -h
```

---

## Quick Reference

```bash
# ────── SSH into EC2 ──────
ssh -i servio-key.pem ec2-user@<ELASTIC_IP>

# ────── Container Management ──────
cd /home/ec2-user/servio
docker compose -f docker-compose.prod.yml up -d       # Start
docker compose -f docker-compose.prod.yml down         # Stop
docker compose -f docker-compose.prod.yml restart      # Restart
docker compose -f docker-compose.prod.yml logs -f      # Live logs
docker compose -f docker-compose.prod.yml ps           # Status

# ────── Deploy Manually ──────
# Backend:
docker compose -f docker-compose.prod.yml pull
docker compose -f docker-compose.prod.yml up -d

# Frontend:
aws s3 sync frontend/dist/ s3://servio-frontend --delete

# ────── Useful URLs ──────
# Frontend: https://d1234567890.cloudfront.net
# Backend:  http://<ELASTIC_IP>:3001/api/services
# GitHub:   https://github.com/<username>/Servio/actions
# ECR:      AWS Console → ECR → servio-backend
```

---

*This guide was written for the Servio university project. For production-grade deployments, consider using AWS ECS Fargate, Application Load Balancer, and AWS Secrets Manager.*
