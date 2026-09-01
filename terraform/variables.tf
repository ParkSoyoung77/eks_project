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
  description = "생성할 데이터베이스 이름"
  type        = string
  default     = "testdb"
}