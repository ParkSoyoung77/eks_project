# ==================================================================
# 1. 네트워크 (VPC, public 3 / private 3 / eks전용 private 3)
# ==================================================================
module "network" {
    source      = "./modules/network"
    name_prefix = var.name_prefix
    azs         = var.azs
}

# ==================================================================
# 2. 보안그룹
# ==================================================================
module "security" {
    source      = "./modules/security"
    name_prefix = var.name_prefix
    vpc_id      = module.network.vpc_id
}

# ==================================================================
# 3. IAM (EC2 인스턴스 프로파일, Lambda/EKS 는 각 모듈 내부에서 처리)
# ==================================================================
module "iam" {
    source      = "./modules/iam"
    name_prefix = var.name_prefix
}

# ==================================================================
# 4. ACM 인증서 (sy99.cloud 와일드카드 또는 서브도메인용)
# ==================================================================
module "acm" {
    source         = "./modules/acm"
    name_prefix    = var.name_prefix
    domain_name    = var.site_domain
    hosted_zone_id = var.hosted_zone_id
}

# ==================================================================
# 5. RDS (item 2)
# ==================================================================
module "rds" {
    source             = "./modules/rds"
    name_prefix        = var.name_prefix
    vpc_id             = module.network.vpc_id
    private_subnet_ids = module.network.private_subnet_ids
    security_group_id  = module.security.rds_sg_id

    depends_on = [module.network, module.security]
}

# ==================================================================
# 6. domain-s3 (item 3/6: test.sy99.cloud + API GW 백엔드)
# ==================================================================
module "domain_s3" {
    source      = "./modules/domain-s3"
    name_prefix = var.name_prefix
    bucket_name = var.site_domain
}

# ==================================================================
# 7. static-site (item 5: 순수 S3 2개, CloudFront/APIGW 미사용)
# ==================================================================
module "static_site" {
    source        = "./modules/static-site"
    name_prefix   = var.name_prefix
    bucket_name_1 = "st17-test-bucket"
    bucket_name_2 = "st17-test-bucket-2"
}

# ==================================================================
# 8. Lambda (item 9: 교육생정보, RDS Proxy 연동)
# ==================================================================
module "lambda" {
    source              = "./modules/lambda"
    name_prefix         = var.name_prefix
    private_subnet_ids  = module.network.private_subnet_ids
    security_group_id   = module.security.lambda_sg_id
    db_secret_arn       = module.rds.db_secret_arn
    db_host             = module.rds.proxy_endpoint
    db_name             = module.rds.db_name

    depends_on = [module.rds]
}

# ==================================================================
# 9. api-gateway (item 3/6/9: /company, /student, /docker, /api/students)
# ==================================================================
module "api_gateway" {
    source               = "./modules/api-gateway"
    name_prefix          = var.name_prefix
    domain_name          = var.site_domain
    s3_website_endpoint  = module.domain_s3.website_endpoint
    lambda_invoke_arn    = module.lambda.invoke_arn
    lambda_function_name = module.lambda.function_name
    acm_certificate_arn  = module.acm.certificate_arn
    hosted_zone_id       = var.hosted_zone_id
    alb_dns_name         = module.alb.alb_dns_name

    depends_on = [module.alb]
}

# ==================================================================
# 10. ALB (item 7/8: docker-compose EC2 앞단, HTTPS 리스너)
# ==================================================================
module "alb" {
    source              = "./modules/alb"
    name_prefix         = var.name_prefix
    vpc_id              = module.network.vpc_id
    public_subnet_ids   = module.network.public_subnet_ids
    security_group_id   = module.security.alb_sg_id
    acm_certificate_arn = module.acm.certificate_arn
}

# ==================================================================
# 11. Compute (item 4/7: docker-compose EC2 + ASG, S3 배포 아티팩트 포함)
# ==================================================================
module "compute" {
    source                  = "./modules/compute"
    name_prefix             = var.name_prefix
    vpc_id                  = module.network.vpc_id
    subnet_ids              = module.network.private_subnet_ids
    security_group_id       = module.security.ec2_sg_id
    ec2_role_name           = module.iam.ec2_role_name
    instance_profile_name   = module.iam.ec2_instance_profile_name
    key_name                = var.key_name
    ecr_registry            = local.ecr_registry
    alb_target_group_arn    = module.alb.target_group_arn

    depends_on = [module.alb, module.iam]
}

# ==================================================================
# 12. EKS (item 10/11)
# ==================================================================
module "eks" {
    source              = "./modules/eks"
    name_prefix         = var.name_prefix
    vpc_id              = module.network.vpc_id
    private_subnet_ids  = module.network.eks_private_subnet_ids
    cluster_name        = "${var.name_prefix}-eks-cluster"
    node_group_name     = "${var.name_prefix}-eks-nodegroup"
}

# ==================================================================
# (추가) 13. 루트 레벨 보안그룹 규칙 (모듈 간 순환참조 회피)
# ==================================================================
resource "aws_security_group_rule" "rds_from_eks_node" {
    type                     = "ingress"
    from_port                = 3306
    to_port                  = 3306
    protocol                 = "tcp"
    security_group_id        = module.security.rds_sg_id
    source_security_group_id = module.eks.cluster_primary_security_group_id
    description              = "eks node to RDS proxy"
}

resource "aws_security_group_rule" "rds_from_ec2" {
    type                     = "ingress"
    from_port                = 3306
    to_port                  = 3306
    protocol                 = "tcp"
    security_group_id        = module.security.rds_sg_id
    source_security_group_id = module.security.ec2_sg_id
    description              = "ec2 to RDS for init.sql via mysql client"
}

resource "aws_security_group_rule" "eks_node_from_alb" {
    type                     = "ingress"
    from_port                = 30080
    to_port                  = 30080
    protocol                 = "tcp"
    security_group_id        = module.eks.cluster_primary_security_group_id
    source_security_group_id = module.security.alb_sg_id
    description              = "alb health check and traffic to eks nginx nodeport"
}

# ==================================================================
# (추가) 14. 헬름 설치
# ==================================================================
resource "helm_release" "std17_alb_controller" {
    name       = "aws-load-balancer-controller"
    repository = "https://aws.github.io/eks-charts"
    chart      = "aws-load-balancer-controller"
    namespace  = "kube-system"

    set {
        name  = "clusterName"
        value = module.eks.cluster_id
    }

    set {
        name  = "serviceAccount.create"
        value = "true"
    }

    set {
        name  = "serviceAccount.name"
        value = "aws-load-balancer-controller"
    }

    set {
        name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
        value = module.eks.alb_controller_role_arn
    }

    set {
        name  = "region"
        value = var.aws_region
    }

    set {
        name  = "vpcId"
        value = module.network.vpc_id
    }

    depends_on = [module.eks]
}