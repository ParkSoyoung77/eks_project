data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
    ecr_registry = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.region}.amazonaws.com"
}