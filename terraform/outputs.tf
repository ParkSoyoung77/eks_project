output "vpc_id" {
    description = "VPC ID"
    value       = module.network.vpc_id
}

output "alb_dns_name" {
    description = "docker-compose EC2 앞단 ALB DNS"
    value       = module.alb.alb_dns_name
}

output "site_invoke_url" {
    description = "item3/6/9 REST API 커스텀 도메인 URL"
    value       = module.api_gateway.invoke_url
}

output "static_address_1" {
    description = "item5 정적 웹사이트 주소 1"
    value       = module.static_site.static_address_1
}

output "static_address_2" {
    description = "item5 정적 웹사이트 주소 2"
    value       = module.static_site.static_address_2
}

output "rds_db_subnet_group_name" {
    description = "item2 제출용 - 서브넷 그룹 이름"
    value       = module.rds.db_subnet_group_name
}

output "rds_mysql_dns" {
    description = "item2 제출용 - MySQL DNS"
    value       = module.rds.db_endpoint
}

output "rds_proxy_dns" {
    description = "item2 제출용 - 프록시 DNS"
    value       = module.rds.proxy_endpoint
}

output "eks_cluster_name" {
    description = "EKS 클러스터 이름"
    value       = module.eks.cluster_id
}

output "eks_cluster_endpoint" {
    description = "EKS API 서버 엔드포인트"
    value       = module.eks.cluster_endpoint
}

output "lambda_function_name" {
    description = "item9 Lambda 함수 이름"
    value       = module.lambda.function_name
}

output "rds_db_secret_arn" {
    description = "RDS 마스터 계정 Secrets Manager ARN"
    value       = module.rds.db_secret_arn
}

output "eks_target_group_arn" {
    description = "EKS TargetGroupBinding용 ALB 타겟그룹 ARN"
    value       = module.alb.eks_target_group_arn
}