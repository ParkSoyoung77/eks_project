variable "name_prefix" {
    type    = string
    default = "std17-test"
}

variable "domain_name" {
    description = "인증서를 발급할 도메인"
    type        = string
}

variable "hosted_zone_id" {
    description = "DNS 검증용 Route53 호스팅 영역 ID"
    type        = string
}