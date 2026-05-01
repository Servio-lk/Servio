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
16. [Set Up Amazon SES for Supabase Email](#16-set-up-amazon-ses-for-supabase-email)

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
│   Amazon CloudFront  │   │   EC2 t3.micro           │
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
                           │   (PostgreSQL + Auth)│──────► Amazon SES
                           └──────────────────────┘       (SMTP Email)
```

**Why this architecture?**

| Component | Service | Free Tier Limit | Why |
|---|---|---|---|
| Frontend | S3 + CloudFront | 5 GB + 1 TB transfer | Static site = no server needed, globally cached |
| Backend | EC2 t3.micro | 750 hrs/month (12 months) | Spring Boot needs a JVM runtime |
| Backend Image | ECR | 500 MB storage | Docker image registry |
| Database | Supabase (external) | Free plan | Already using Supabase, no AWS cost |
| Email (SMTP) | Amazon SES | 3,000 msgs/month (12 months) | Reliable email delivery for auth OTPs & password resets |

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
   - `AmazonSESFullAccess` *(only needed if managing SES via CLI; not required for SMTP sending)*
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
  --output text > servio-key-new.pem

chmod 400 servio-key-new.pem
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
  --instance-type t3.micro \
  --key-name servio-key \
  --security-groups servio-sg \
  --block-device-mappings '[{"DeviceName":"/dev/xvda","Ebs":{"VolumeSize":20,"VolumeType":"gp3"}}]' \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=servio-backend}]' \
  --count 1
```

> **Note**: `t2.micro` is **no longer free tier eligible** in `ap-south-1`. Use `t3.micro` instead. You can check eligible types with:
> ```bash
> aws ec2 describe-instance-types --region ap-south-1 \
>   --filters Name=free-tier-eligible,Values=true \
>   --query "InstanceTypes[].InstanceType" --output table
> ```
> The AMI ID `ami-0f58b397bc5c1f2e8` is for **Ubuntu 24.04 LTS** in `ap-south-1`. The default SSH username is `ubuntu` (not `ec2-user`). If you're using a different region, find the correct AMI ID in the AWS Console under EC2 → Launch Instance.

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
ssh -i servio-key-new.pem ubuntu@<ELASTIC_IP>
```

### 8.2 Install Docker & Docker Compose
```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker using the official convenience script
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Start and enable Docker
sudo systemctl start docker
sudo systemctl enable docker

# Add ubuntu to docker group (avoids needing sudo)
sudo usermod -aG docker ubuntu

# Install AWS CLI (if not already installed)
sudo apt install -y awscli
aws --version

# Log out and back in for group changes
exit
```

```bash
# SSH back in
ssh -i servio-key-new.pem ubuntu@<ELASTIC_IP>

# Verify
docker --version
docker compose version
```

---

## 9. Configure the EC2 Instance

### 9.1 Enable Swap Space (Critical for t3.micro!)

The t3.micro only has 1 GB RAM. Swap prevents out-of-memory kills.

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
mkdir -p /home/ubuntu/servio
cd /home/ubuntu/servio
```

### 9.4 Create the `.env` File

```bash
cat > .env << 'EOF'
# ---- Supabase Database (Session Pooler — IPv4 compatible) ----
# Get these from: Supabase Dashboard → Database → Connect → Session Pooler
DB_HOST=aws-1-ap-south-1.pooler.supabase.com
DB_PORT=5432
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
> **Important:** Do NOT use the direct database connection (`db.xxx.supabase.co`). It resolves to IPv6 only, which EC2 instances typically can't reach. Always use the **Session Pooler** connection from the Supabase Dashboard.

### 9.5 Copy the Production Compose File

```bash
# From your local machine:
scp -i servio-key-new.pem docker-compose.prod.yml ubuntu@<ELASTIC_IP>:/home/ubuntu/servio/
```

---

## 10. First Manual Deploy

### 10.1 Build and Push Backend Image (from your local machine)

```bash
# Login to ECR
aws ecr get-login-password --region ap-south-1 | \
  docker login --username AWS --password-stdin \
  <AWS_ACCOUNT_ID>.dkr.ecr.ap-south-1.amazonaws.com

# Build the backend image (--platform targets EC2's x86_64, --provenance=false avoids manifest issues)
docker build --platform linux/amd64 --provenance=false -t servio-backend ./backend

# Tag it
docker tag servio-backend:latest \
  <AWS_ACCOUNT_ID>.dkr.ecr.ap-south-1.amazonaws.com/servio-backend:latest

# Push to ECR
docker push <AWS_ACCOUNT_ID>.dkr.ecr.ap-south-1.amazonaws.com/servio-backend:latest
```

### 10.2 Deploy on EC2

```bash
# SSH into EC2
ssh -i servio-key-new.pem ubuntu@<ELASTIC_IP>

cd /home/ubuntu/servio

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
| `EC2_SSH_KEY` | `-----BEGIN RSA PRIVATE...` | Contents of `servio-key-new.pem` |
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
ssh -i servio-key-new.pem ubuntu@<ELASTIC_IP>

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
cat > /home/ubuntu/health-check.sh << 'SCRIPT'
#!/bin/bash
if ! curl -sf http://localhost:3001/api/services > /dev/null 2>&1; then
  echo "$(date): Backend is down, restarting..." >> /home/ubuntu/health-check.log
  cd /home/ubuntu/servio
  docker compose -f docker-compose.prod.yml restart backend
fi
SCRIPT

chmod +x /home/ubuntu/health-check.sh

# Run every 5 minutes
(crontab -l 2>/dev/null; echo "*/5 * * * * /home/ubuntu/health-check.sh") | crontab -
```

---

## 14. Cost Optimization

### Free Tier Limits (12 months)

| Service | Free Limit | Your Usage | Status |
|---|---|---|---|
| EC2 t3.micro | 750 hrs/month | ~730 hrs (24/7) | ✅ Within limit |
| EBS (gp3) | 30 GB | 20 GB | ✅ Within limit |
| S3 | 5 GB storage | ~50 MB (frontend) | ✅ Within limit |
| S3 Requests | 20K GET, 2K PUT | Varies | ✅ Likely within limit |
| CloudFront | 1 TB transfer | Low traffic | ✅ Within limit |
| ECR | 500 MB | ~300 MB (3 images max) | ✅ Within limit |
| Data Transfer | 100 GB out | Low traffic | ✅ Within limit |
| Elastic IP | Free (if associated) | 1 IP, associated | ✅ Free |
| SES (Email) | 3,000 msgs/month | Auth emails only | ✅ Within limit |

### Tips to Stay Within Free Tier

1. **Never run more than 1 EC2 instance** — 750 hrs is for all t3.micro instances combined
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
- EC2 t3.micro: ~$7.60/month
- EBS 20 GB: ~$1.60/month  
- S3 + CloudFront: ~$0.50/month
- ECR: ~$0.10/month
- SES: ~$0.10/month (at low volume)
- **Total: ~$9.90/month**

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
cd /home/ubuntu/servio
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
ssh -i servio-key-new.pem ubuntu@<ELASTIC_IP>

# ────── Container Management ──────
cd /home/ubuntu/servio
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

## 16. Set Up Amazon SES for Supabase Email

Supabase's built-in email service has **strict rate limits** (3 emails/hour on the free plan) and sends from a generic `noreply@mail.app.supabase.io` address. For production use — especially signup OTP verification, password resets, and email confirmations — you should configure **Amazon SES** as a custom SMTP provider.

> **Why SES?** You're already on AWS, it's included in the Free Tier (3,000 messages/month for 12 months), and it provides high deliverability with SPF/DKIM authentication.

### 16.1 Choose Your SES Region

Amazon SES is available in specific regions. Pick the one closest to your Supabase project:

| Region | SMTP Endpoint |
|---|---|
| Mumbai (ap-south-1) | `email-smtp.ap-south-1.amazonaws.com` |
| US East (us-east-1) | `email-smtp.us-east-1.amazonaws.com` |
| EU (eu-west-1) | `email-smtp.eu-west-1.amazonaws.com` |
| Singapore (ap-southeast-1) | `email-smtp.ap-southeast-1.amazonaws.com` |

> Since your infrastructure is in `ap-south-1`, use the Mumbai endpoint for the lowest latency.

### 16.2 Verify a Sender Identity

SES requires you to verify the email address or domain you'll send from.

#### Option A: Verify an Email Address (Quickest — Good for Testing)

1. Go to **Amazon SES Console** → **Verified identities** → **Create identity**
2. Select **Email address**
3. Enter your sender email (e.g., `noreply@servio.lk` or `servio.team@gmail.com`)
4. Click **Create identity**
5. Check your inbox and click the verification link from AWS

#### Option B: Verify a Domain (Recommended for Production)

1. Go to **Amazon SES Console** → **Verified identities** → **Create identity**
2. Select **Domain**
3. Enter your domain (e.g., `servio.lk`)
4. Enable **DKIM** (Easy DKIM is recommended)
5. Click **Create identity**
6. Add the DNS records AWS provides to your domain registrar:

```
# Example DNS records SES will ask you to add:

# DKIM (3 CNAME records)
xxxxxxxx._domainkey.servio.lk  →  xxxxxxxx.dkim.amazonses.com
yyyyyyyy._domainkey.servio.lk  →  yyyyyyyy.dkim.amazonses.com
zzzzzzzz._domainkey.servio.lk  →  zzzzzzzz.dkim.amazonses.com

# SPF (TXT record — add to existing or create new)
servio.lk  TXT  "v=spf1 include:amazonses.com ~all"

# Optional: Custom MAIL FROM domain
mail.servio.lk  MX   10 feedback-smtp.ap-south-1.amazonses.com
mail.servio.lk  TXT  "v=spf1 include:amazonses.com ~all"
```

> ⚠️ DNS propagation can take up to 72 hours, but usually completes within 1–2 hours.

### 16.3 Request Production Access (Exit Sandbox)

By default, new SES accounts are in **Sandbox mode** — you can only send emails to verified addresses. To send to any recipient (i.e., your actual users), you must request production access.

1. Go to **Amazon SES Console** → **Account dashboard**
2. In the **Sending statistics** section, click **Request production access**
3. Fill in the request:
   - **Mail type**: Transactional
   - **Website URL**: Your application URL
   - **Use case description**: Example below

```
We are building Servio, a vehicle service management platform. 
We need SES for transactional emails only:
- Signup email OTP verification codes
- Password reset links
- Account confirmation emails

Estimated volume: <100 emails/day.
We have a clear unsubscribe process and do not send marketing emails.
Bounce/complaint notifications will be monitored via SES dashboard.
```

4. Click **Submit request**

> ⏱️ AWS typically reviews and approves within 24 hours. You can continue with sandbox testing (using verified emails) while you wait.

### 16.4 Create SMTP Credentials

1. Go to **Amazon SES Console** → **SMTP settings** (left sidebar)
2. Note the **SMTP endpoint** for your region (e.g., `email-smtp.ap-south-1.amazonaws.com`)
3. Click **Create SMTP credentials**
4. This opens the IAM console — leave the default IAM user name or customize it
5. Click **Create user**
6. **Save the credentials immediately** — you won't be able to see the password again:

```
┌──────────────────────────────────────────────────────────┐
│  SMTP Username:  AKIA...........................         │
│  SMTP Password:  BL8f...........................         │
└──────────────────────────────────────────────────────────┘
```

> ⚠️ **SMTP credentials are NOT the same as your AWS Access Key.** SES generates a special derived password. Always use the credentials from this page.

### 16.5 Configure Supabase to Use SES

Now connect SES to your Supabase project:

1. Go to **[Supabase Dashboard](https://supabase.com/dashboard)**
2. Select your Servio project
3. Navigate to **Authentication** → **SMTP Settings** (under Email section)
4. Toggle **Enable Custom SMTP** to **ON**
5. Fill in the following:

| Field | Value |
|---|---|
| **Sender email** | `noreply@servio.lk` (or your verified email) |
| **Sender name** | `Servio` |
| **Host** | `email-smtp.ap-south-1.amazonaws.com` |
| **Port** | `587` |
| **Minimum interval** | `30` (seconds between emails to same user) |
| **Username** | Your SMTP username from Step 16.4 |
| **Password** | Your SMTP password from Step 16.4 |

6. Click **Save**

> 💡 Use port `587` with STARTTLS (Supabase handles this automatically). Port `465` (TLS Wrapper) also works but `587` is recommended.

### 16.6 Customize Email Templates (Optional)

While you're in the Supabase Auth settings, you can customize the email templates:

1. Go to **Authentication** → **Email Templates**
2. Available templates:
   - **Confirm signup** — OTP/confirmation email sent on registration
   - **Magic link** — Passwordless login link
   - **Change email address** — Email change confirmation
   - **Reset password** — Password reset link/OTP

Example custom signup template:
```html
<h2>Welcome to Servio! 🚗</h2>
<p>Your verification code is:</p>
<h1 style="letter-spacing: 8px; font-size: 32px; text-align: center;
    background: #f4f4f5; padding: 16px; border-radius: 8px;">
  {{ .Token }}
</h1>
<p>This code expires in 1 hour.</p>
<p style="color: #888;">If you didn't create a Servio account, you can safely ignore this email.</p>
```

### 16.7 Test the Integration

#### Quick Test (While in Sandbox)

If you're still in SES Sandbox, first verify the recipient email in SES:
1. Go to **SES Console** → **Verified identities** → **Create identity** → **Email address**
2. Verify the test recipient email

Then test:
1. Go to your Servio app signup page
2. Register with the verified test email
3. Check the inbox for the OTP email
4. Verify it arrives from your custom sender address (not `noreply@mail.app.supabase.io`)

#### Production Test (After Sandbox Exit)

1. Sign up with any email address
2. Trigger a password reset
3. Check:
   - ✅ Email arrives within a few seconds
   - ✅ Sender shows your custom address and name
   - ✅ Email doesn't land in spam
   - ✅ DKIM signature passes (check email headers)

#### Using AWS CLI to Test SES Directly

```bash
aws ses send-email \
  --from "noreply@servio.lk" \
  --destination "ToAddresses=your-test@gmail.com" \
  --message "Subject={Data='SES Test'},Body={Text={Data='Hello from Servio SES!'}}" \
  --region ap-south-1
```

### 16.8 Monitor SES Sending

1. **SES Dashboard**: Go to **SES Console** → **Account dashboard** to view:
   - Send rate and quota
   - Bounce rate (keep below 5%)
   - Complaint rate (keep below 0.1%)

2. **Supabase Logs**: Go to **Supabase Dashboard** → **Logs** → **Auth** to check for email delivery errors

### 16.9 Troubleshooting SES

| Issue | Cause | Fix |
|---|---|---|
| `Email address is not verified` | Sender email not verified in SES | Verify the sender email/domain in SES Console |
| `Message rejected` | Still in Sandbox, sending to unverified recipient | Request production access (Section 16.3) or verify recipient |
| `SMTP credentials invalid` | Using AWS Access Key instead of SMTP credentials | Generate proper SMTP credentials from SES Console (Section 16.4) |
| `Connection timed out` | Wrong SMTP host or port | Use `email-smtp.<region>.amazonaws.com` on port `587` |
| Emails landing in spam | Missing SPF/DKIM records | Add the DNS records from Section 16.2 |
| Supabase shows `email rate limit exceeded` | Custom SMTP rate limit too low | Increase the "Minimum interval" in Supabase SMTP settings |
| `Throttling - Maximum sending rate exceeded` | Exceeded SES send rate | Request a sending rate increase in SES Console |

### 16.10 SES Cost Summary

| Tier | Limit | Price |
|---|---|---|
| Free Tier (12 months) | 3,000 messages/month | **$0.00** |
| After Free Tier | Per message | **$0.10 / 1,000 emails** |
| Attachments | Per GB | **$0.12 / GB** |

> For a university project sending auth emails only, you'll likely stay well within the free tier. Even after it expires, 1,000 auth emails costs just $0.10.

---

*This guide was written for the Servio university project. For production-grade deployments, consider using AWS ECS Fargate, Application Load Balancer, and AWS Secrets Manager.*
