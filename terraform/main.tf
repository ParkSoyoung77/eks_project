module "lambda" {
    source              = "./modules/lambda"
    name_prefix         = var.name_prefix
    private_subnet_ids  = module.network.eks_private_subnet_ids
    security_group_id   = module.security.lambda_sg_id
    db_secret_arn       = module.rds.db_secret_arn
    db_host             = module.rds.proxy_endpoint
    db_name             = module.rds.db_name
}

module "api_gateway" {
    source               = "./modules/api-gateway"
    name_prefix          = var.name_prefix
    domain_name          = "test.domain.class"
    s3_website_endpoint  = module.domain_s3.website_endpoint
    lambda_invoke_arn    = module.lambda.invoke_arn
    lambda_function_name = module.lambda.function_name
    acm_certificate_arn  = module.acm.certificate_arn
    hosted_zone_id       = var.hosted_zone_id
}