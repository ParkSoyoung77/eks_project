variable "name_prefix" {
    type    = string
    default = "std17-test"
}

variable "vpc_cidr" {
    description = "VPC CIDR 블록"
    type        = string
    default     = "10.0.0.0/16"
}

variable "azs" {
    description = "사용할 가용영역 리스트 (subnet count.index 순서와 매칭)"
    type        = list(string)
    default     = ["ap-northeast-3a", "ap-northeast-3b", "ap-northeast-3c"]
}