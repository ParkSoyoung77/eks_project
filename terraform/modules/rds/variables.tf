variable "name_prefix" {
    type    = string
    default = "std17-test"
}

variable "vpc_id" {
    type = string
}

variable "private_subnet_ids" {
    description = "RDS 서브넷 그룹에 사용할 프라이빗 서브넷 ID 리스트"
    type        = list(string)
}

variable "security_group_id" {
    type = string
}

variable "db_name" {
    description = "생성할 데이터베이스 이름"
    type        = string
    default     = "rdsdb"
}

variable "master_username" {
    type    = string
    default = "adm"
}