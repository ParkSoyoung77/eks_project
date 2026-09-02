variable "name_prefix" {
    type    = string
    default = "std17-test"
}

variable "vpc_id" {
    type = string
}

variable "public_subnet_ids" {
    type = list(string)
}

variable "security_group_id" {
    type = string
}

variable "ec2_role_name" {
    type = string
}

variable "instance_profile_name" {
    type = string
}

variable "key_name" {
    type    = string
    default = "std17-key"
}

variable "instance_type" {
    type    = string
    default = "t3.small"
}

variable "ecr_registry" {
    description = "ECR 레지스트리 주소 (계정ID.dkr.ecr.리전.amazonaws.com)"
    type        = string
}

variable "alb_target_group_arn" {
    type = string
}