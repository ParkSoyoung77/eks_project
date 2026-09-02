variable "name_prefix" {
    type    = string
    default = "std17-test"
}

variable "vpc_id" {
    description = "EC2가 속할 VPC ID"
    type        = string
}

variable "subnet_ids" {
    description = "ASG가 사용할 서브넷 ID 리스트 (3-tier 구조상 프라이빗 서브넷을 전달)"
    type        = list(string)
}

variable "security_group_id" {
    description = "EC2에 붙일 보안그룹 ID (security 모듈의 ec2_sg_id)"
    type        = string
}

variable "ec2_role_name" {
    description = "S3 배포 버킷 읽기 정책을 붙일 EC2 IAM 역할 이름 (iam 모듈의 ec2_role_name)"
    type        = string
}

variable "instance_profile_name" {
    description = "EC2에 연결할 인스턴스 프로파일 이름 (iam 모듈의 ec2_instance_profile_name)"
    type        = string
}

variable "key_name" {
    description = "EC2 SSH 접속용 키페어 이름"
    type        = string
    default     = "std17-key"
}

variable "instance_type" {
    description = "docker-compose를 실행할 EC2 인스턴스 유형"
    type        = string
    default     = "t3.small"
}

variable "ecr_registry" {
    description = "ECR 레지스트리 주소 (계정ID.dkr.ecr.리전.amazonaws.com)"
    type        = string
}

variable "alb_target_group_arn" {
    description = "ASG를 연결할 ALB 타겟그룹 ARN (alb 모듈의 target_group_arn)"
    type        = string
}