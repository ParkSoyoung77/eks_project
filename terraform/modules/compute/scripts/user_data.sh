#!/bin/bash
set -e

# ── Docker 설치 (Ubuntu) ──────────────────────────
apt-get update -y
apt-get install -y ca-certificates curl gnupg unzip

install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

usermod -aG docker ubuntu

# ── AWS CLI v2 설치 ────────────────────────────────
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip"
unzip -q /tmp/awscliv2.zip -d /tmp
/tmp/aws/install

# ── 배포 파일 수신 (S3 -> EC2) ──────────────────────
mkdir -p /home/ubuntu/app/fastapi
aws s3 cp s3://${deploy_bucket_name}/docker-compose.yaml /home/ubuntu/app/docker-compose.yaml
aws s3 cp s3://${deploy_bucket_name}/fastapi.env /home/ubuntu/app/fastapi/.env

chown -R ubuntu:ubuntu /home/ubuntu/app

# ── ECR 로그인 및 서비스 기동 ───────────────────────
aws ecr get-login-password --region ap-northeast-3 | \
  docker login --username AWS --password-stdin ${ecr_registry}

export ECR_REGISTRY=${ecr_registry}

cd /home/ubuntu/app
docker compose pull
docker compose up -d