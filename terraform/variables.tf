variable "aws_region" {
    description = "리소스를 생성할 AWS 리전"
    type        = string
    default     = "ap-northeast-3"
}

variable "azs" {
    description = "사용할 가용영역 리스트"
    type        = list(string)
    default     = ["ap-northeast-3a", "ap-northeast-3b", "ap-northeast-3c"]
}

variable "key_name" {
    description = "EC2 키페어 이름"
    type        = string
    default     = "std17-key"
}

variable "db_name" {
    description = "docker-compose MySQL 컨테이너용 데이터베이스 이름"
    type        = string
    default     = "testdb"
}

variable "name_prefix" {
    description = "모든 리소스 Name/Tag 접두사"
    type        = string
    default     = "std17-test"
}

variable "domain_name" {
    description = "루트 도메인"
    type        = string
    default     = "sy99.cloud"
}

variable "site_domain" {
    description = "item3용 서브도메인"
    type        = string
    default     = "test.sy99.cloud"
}

variable "hosted_zone_id" {
    description = "sy99.cloud Route53 호스팅 영역 ID"
    type        = string
}