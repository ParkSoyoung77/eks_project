variable "name_prefix" {
    type    = string
    default = "std17-test"
}

variable "domain_name" {
    type = string
}

variable "s3_website_endpoint" {
    type = string
}

variable "lambda_invoke_arn" {
    type = string
}

variable "lambda_function_name" {
    type = string
}

variable "acm_certificate_arn" {
    type = string
}

variable "hosted_zone_id" {
    type = string
}