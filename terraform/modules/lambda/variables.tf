variable "name_prefix" {
    type    = string
    default = "std17-test"
}

variable "private_subnet_ids" {
    description = "Lambda가 위치할 프라이빗 서브넷 ID 리스트"
    type        = list(string)
}

variable "security_group_id" {
    type = string
}

variable "db_secret_arn" {
    description = "RDS 마스터 계정 Secrets Manager ARN"
    type        = string
}

variable "db_host" {
    description = "RDS Proxy 엔드포인트"
    type        = string
}

variable "db_name" {
    type = string
}