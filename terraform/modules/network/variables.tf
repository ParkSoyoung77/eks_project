variable "vpc_cidr" {
    description = "VPC CIDR 블록"
    type        = string
    default     = "10.0.0.0/16"
}

variable "azs" {
    description = "사용할 가용영역 리스트 (public/private subnet count.index 순서와 매칭)"
    type        = list(string)
    default     = ["ap-northeast-3a", "ap-northeast-3b", "ap-northeast-3c"]
}

variable "aws_region" {
  description = "S3 Gateway 엔드포인트 서비스명 구성용"
  type        = string
  default     = "p-northeast-3"
}