# std17-test 중간평가 프로젝트

AWS 3-tier 아키텍처 기반 인프라 구축 (Terraform + Docker + Kubernetes)

## 아키텍처 개요

- **3-tier**: Public(ALB, NAT, IGW) / Private(EC2, RDS) / EKS 전용 Private

## 네트워크

- VPC 1개, 서브넷 9개 (Public 3 / Private 3 / EKS전용 Private 3)
- NAT Gateway 1개, S3 Gateway Endpoint
- 라우팅 테이블 3개 (Public/Private/EKS전용 각 1)

## 컴퓨트

| 계층 | 구성 | 배포 방식 |
|---|---|---|
| EC2 | Nginx + FastAPI + MySQL | Docker Compose, ASG(1~2), userdata |
| EKS | Nginx + FastAPI | K8s Deployment, ConfigMap/Secret |
| Lambda | 교육생 조회 | Python, RDS Proxy 연동 |

## 데이터베이스

- RDS MySQL 8.4.10 (db.t4g.micro), 단일 AZ
- RDS Proxy + Secrets Manager (보안 암호)
- 스키마: tclass / tstudent / tscore (JOIN 구조)

## 스토리지 (S3)

- domain-s3: API Gateway 백엔드 (company/student/docker 정적 파일)
- static-site: 순수 정적 웹사이트 2개 (item5, CloudFront/APIGW 미사용)
- deploy-artifacts: docker-compose.yaml, .env 배포용

## 라우팅 (test.sy99.cloud)

| 경로 | 대상 |
|---|---|
| `/` | ALB → EC2 (index.html) |
| `/company`, `/student`, `/docker` | S3 정적 |
| `/api/students` | Lambda |
| `/test` | ALB → EKS 타겟그룹 (성적등록) |

## 로드밸런서

- ALB 1개 공용 (EC2 + EKS 트래픽 통합)
- 443: HTTPS(ACM), 80: HTTPS 리다이렉트, 8080: API Gateway 내부 프록시용
- EKS 연동: TargetGroupBinding + AWS Load Balancer Controller(IRSA)

## 이미지 관리 (ECR)

- std17-test-mysql, std17-test-fastapi(ec2/eks 태그), std17-test-nginx(ec2/eks 태그)

## Terraform 모듈 구성

```
network / security / iam / acm / rds / domain-s3 / static-site /
lambda / api-gateway / alb / compute / eks
```

## 배포 순서

1. ECR 레포 생성 → 이미지 빌드/push (EC2용 3개)
2. `terraform apply` (network ~ eks, ALB Controller까지 helm_release로 자동 설치)
3. EKS용 이미지 빌드/push
4. kubeconfig 연결 → ConfigMap/Secret/Deployment/Service/TargetGroupBinding 순서로 kubectl apply

## 주요 산출물 (제출용)

- RDS: 서브넷 그룹 이름 / MySQL DNS / 프록시 DNS
- S3(item5): 정적 주소 1, 2
- 전체 구성 zip: index.html, main.py, default.conf, init.sql, Dockerfile, docker-compose.yaml