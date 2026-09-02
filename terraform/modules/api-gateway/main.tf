resource "aws_api_gateway_rest_api" "std17_site_api" {
    name = "${var.name_prefix}-site-api"
}

# ==================================================================
# /company
resource "aws_api_gateway_resource" "std17_company" {
    rest_api_id = aws_api_gateway_rest_api.std17_site_api.id
    parent_id   = aws_api_gateway_rest_api.std17_site_api.root_resource_id
    path_part   = "company"
}

resource "aws_api_gateway_method" "std17_company_get" {
    rest_api_id   = aws_api_gateway_rest_api.std17_site_api.id
    resource_id   = aws_api_gateway_resource.std17_company.id
    http_method   = "GET"
    authorization = "NONE"
}

resource "aws_api_gateway_integration" "std17_company_get" {
    rest_api_id             = aws_api_gateway_rest_api.std17_site_api.id
    resource_id             = aws_api_gateway_resource.std17_company.id
    http_method             = aws_api_gateway_method.std17_company_get.http_method
    type                    = "HTTP_PROXY"
    integration_http_method = "GET"
    uri                     = "http://${var.s3_website_endpoint}/company.html"
}

# ==================================================================
# /student
resource "aws_api_gateway_resource" "std17_student" {
    rest_api_id = aws_api_gateway_rest_api.std17_site_api.id
    parent_id   = aws_api_gateway_rest_api.std17_site_api.root_resource_id
    path_part   = "student"
}

resource "aws_api_gateway_method" "std17_student_get" {
    rest_api_id   = aws_api_gateway_rest_api.std17_site_api.id
    resource_id   = aws_api_gateway_resource.std17_student.id
    http_method   = "GET"
    authorization = "NONE"
}

resource "aws_api_gateway_integration" "std17_student_get" {
    rest_api_id             = aws_api_gateway_rest_api.std17_site_api.id
    resource_id             = aws_api_gateway_resource.std17_student.id
    http_method             = aws_api_gateway_method.std17_student_get.http_method
    type                    = "HTTP_PROXY"
    integration_http_method = "GET"
    uri                     = "http://${var.s3_website_endpoint}/student.html"
}

# ==================================================================
# /docker (홈) + /docker/{proxy+} (나머지 html)
resource "aws_api_gateway_resource" "std17_docker" {
    rest_api_id = aws_api_gateway_rest_api.std17_site_api.id
    parent_id   = aws_api_gateway_rest_api.std17_site_api.root_resource_id
    path_part   = "docker"
}

resource "aws_api_gateway_method" "std17_docker_get" {
    rest_api_id   = aws_api_gateway_rest_api.std17_site_api.id
    resource_id   = aws_api_gateway_resource.std17_docker.id
    http_method   = "GET"
    authorization = "NONE"
}

resource "aws_api_gateway_integration" "std17_docker_get" {
    rest_api_id             = aws_api_gateway_rest_api.std17_site_api.id
    resource_id             = aws_api_gateway_resource.std17_docker.id
    http_method             = aws_api_gateway_method.std17_docker_get.http_method
    type                    = "HTTP_PROXY"
    integration_http_method = "GET"
    uri                     = "http://${var.s3_website_endpoint}/docker/index.html"
}

resource "aws_api_gateway_resource" "std17_docker_proxy" {
    rest_api_id = aws_api_gateway_rest_api.std17_site_api.id
    parent_id   = aws_api_gateway_resource.std17_docker.id
    path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "std17_docker_proxy_get" {
    rest_api_id   = aws_api_gateway_rest_api.std17_site_api.id
    resource_id   = aws_api_gateway_resource.std17_docker_proxy.id
    http_method   = "GET"
    authorization = "NONE"

    request_parameters = {
        "method.request.path.proxy" = true
    }
}

resource "aws_api_gateway_integration" "std17_docker_proxy_get" {
    rest_api_id             = aws_api_gateway_rest_api.std17_site_api.id
    resource_id             = aws_api_gateway_resource.std17_docker_proxy.id
    http_method             = aws_api_gateway_method.std17_docker_proxy_get.http_method
    type                    = "HTTP_PROXY"
    integration_http_method = "GET"
    uri                     = "http://${var.s3_website_endpoint}/docker/{proxy}"

    request_parameters = {
        "integration.request.path.proxy" = "method.request.path.proxy"
    }
}

# ==================================================================
# /api/students -> Lambda (item9)
resource "aws_api_gateway_resource" "std17_api" {
    rest_api_id = aws_api_gateway_rest_api.std17_site_api.id
    parent_id   = aws_api_gateway_rest_api.std17_site_api.root_resource_id
    path_part   = "api"
}

resource "aws_api_gateway_resource" "std17_api_students" {
    rest_api_id = aws_api_gateway_rest_api.std17_site_api.id
    parent_id   = aws_api_gateway_resource.std17_api.id
    path_part   = "students"
}

resource "aws_api_gateway_method" "std17_api_students_get" {
    rest_api_id   = aws_api_gateway_rest_api.std17_site_api.id
    resource_id   = aws_api_gateway_resource.std17_api_students.id
    http_method   = "GET"
    authorization = "NONE"
}

resource "aws_api_gateway_integration" "std17_api_students_get" {
    rest_api_id             = aws_api_gateway_rest_api.std17_site_api.id
    resource_id             = aws_api_gateway_resource.std17_api_students.id
    http_method             = aws_api_gateway_method.std17_api_students_get.http_method
    type                    = "AWS_PROXY"
    integration_http_method = "POST"
    uri                     = var.lambda_invoke_arn
}

resource "aws_lambda_permission" "std17_apigw_invoke" {
    statement_id  = "AllowAPIGatewayInvoke"
    action        = "lambda:InvokeFunction"
    function_name = var.lambda_function_name
    principal     = "apigateway.amazonaws.com"
    source_arn    = "${aws_api_gateway_rest_api.std17_site_api.execution_arn}/*/*"
}

# ==================================================================
# 루트(/) -> ALB(EC2 docker-compose, index.html)
resource "aws_api_gateway_method" "std17_root_get" {
    rest_api_id   = aws_api_gateway_rest_api.std17_site_api.id
    resource_id   = aws_api_gateway_rest_api.std17_site_api.root_resource_id
    http_method   = "GET"
    authorization = "NONE"
}

resource "aws_api_gateway_integration" "std17_root_get" {
    rest_api_id             = aws_api_gateway_rest_api.std17_site_api.id
    resource_id             = aws_api_gateway_rest_api.std17_site_api.root_resource_id
    http_method             = aws_api_gateway_method.std17_root_get.http_method
    type                    = "HTTP_PROXY"
    integration_http_method = "GET"
    uri                     = "http://${var.alb_dns_name}:8080/"
}

# ==================================================================
# /test -> ALB -> EKS 타겟그룹 (item11 성적등록)
resource "aws_api_gateway_resource" "std17_test" {
    rest_api_id = aws_api_gateway_rest_api.std17_site_api.id
    parent_id   = aws_api_gateway_rest_api.std17_site_api.root_resource_id
    path_part   = "test"
}

resource "aws_api_gateway_method" "std17_test_get" {
    rest_api_id   = aws_api_gateway_rest_api.std17_site_api.id
    resource_id   = aws_api_gateway_resource.std17_test.id
    http_method   = "GET"
    authorization = "NONE"
}

resource "aws_api_gateway_integration" "std17_test_get" {
    rest_api_id             = aws_api_gateway_rest_api.std17_site_api.id
    resource_id             = aws_api_gateway_resource.std17_test.id
    http_method             = aws_api_gateway_method.std17_test_get.http_method
    type                    = "HTTP_PROXY"
    integration_http_method = "GET"
    uri                     = "http://${var.alb_dns_name}:8080/test"
}

resource "aws_api_gateway_resource" "std17_test_proxy" {
    rest_api_id = aws_api_gateway_rest_api.std17_site_api.id
    parent_id   = aws_api_gateway_resource.std17_test.id
    path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "std17_test_proxy_get" {
    rest_api_id   = aws_api_gateway_rest_api.std17_site_api.id
    resource_id   = aws_api_gateway_resource.std17_test_proxy.id
    http_method   = "GET"
    authorization = "NONE"

    request_parameters = {
        "method.request.path.proxy" = true
    }
}

resource "aws_api_gateway_integration" "std17_test_proxy_get" {
    rest_api_id             = aws_api_gateway_rest_api.std17_site_api.id
    resource_id             = aws_api_gateway_resource.std17_test_proxy.id
    http_method             = aws_api_gateway_method.std17_test_proxy_get.http_method
    type                    = "HTTP_PROXY"
    integration_http_method = "GET"
    uri                     = "http://${var.alb_dns_name}:8080/test/{proxy}"

    request_parameters = {
        "integration.request.path.proxy" = "method.request.path.proxy"
    }
}

# ==================================================================
# /score -> ALB -> EKS 타겟그룹 (index.html의 "성적등록" 카드 링크 그대로 사용)
resource "aws_api_gateway_resource" "std17_score" {
    rest_api_id = aws_api_gateway_rest_api.std17_site_api.id
    parent_id   = aws_api_gateway_rest_api.std17_site_api.root_resource_id
    path_part   = "score"
}

resource "aws_api_gateway_method" "std17_score_get" {
    rest_api_id   = aws_api_gateway_rest_api.std17_site_api.id
    resource_id   = aws_api_gateway_resource.std17_score.id
    http_method   = "GET"
    authorization = "NONE"
}

resource "aws_api_gateway_integration" "std17_score_get" {
    rest_api_id             = aws_api_gateway_rest_api.std17_site_api.id
    resource_id             = aws_api_gateway_resource.std17_score.id
    http_method             = aws_api_gateway_method.std17_score_get.http_method
    type                    = "HTTP_PROXY"
    integration_http_method = "GET"
    uri                     = "http://${var.alb_dns_name}:8080/test"
}

resource "aws_api_gateway_resource" "std17_score_proxy" {
    rest_api_id = aws_api_gateway_rest_api.std17_site_api.id
    parent_id   = aws_api_gateway_resource.std17_score.id
    path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "std17_score_proxy_get" {
    rest_api_id   = aws_api_gateway_rest_api.std17_site_api.id
    resource_id   = aws_api_gateway_resource.std17_score_proxy.id
    http_method   = "GET"
    authorization = "NONE"

    request_parameters = {
        "method.request.path.proxy" = true
    }
}

resource "aws_api_gateway_integration" "std17_score_proxy_get" {
    rest_api_id             = aws_api_gateway_rest_api.std17_site_api.id
    resource_id             = aws_api_gateway_resource.std17_score_proxy.id
    http_method             = aws_api_gateway_method.std17_score_proxy_get.http_method
    type                    = "HTTP_PROXY"
    integration_http_method = "GET"
    uri                     = "http://${var.alb_dns_name}:8080/test/{proxy}"

    request_parameters = {
        "integration.request.path.proxy" = "method.request.path.proxy"
    }
}

# ==================================================================
# /loadlist/{proxy+} -> ALB -> EC2 (index.html의 DB 데이터 가져오기)
resource "aws_api_gateway_resource" "std17_loadlist" {
    rest_api_id = aws_api_gateway_rest_api.std17_site_api.id
    parent_id   = aws_api_gateway_rest_api.std17_site_api.root_resource_id
    path_part   = "loadlist"
}

resource "aws_api_gateway_resource" "std17_loadlist_proxy" {
    rest_api_id = aws_api_gateway_rest_api.std17_site_api.id
    parent_id   = aws_api_gateway_resource.std17_loadlist.id
    path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "std17_loadlist_proxy_get" {
    rest_api_id   = aws_api_gateway_rest_api.std17_site_api.id
    resource_id   = aws_api_gateway_resource.std17_loadlist_proxy.id
    http_method   = "GET"
    authorization = "NONE"

    request_parameters = {
        "method.request.path.proxy" = true
    }
}

resource "aws_api_gateway_integration" "std17_loadlist_proxy_get" {
    rest_api_id             = aws_api_gateway_rest_api.std17_site_api.id
    resource_id             = aws_api_gateway_resource.std17_loadlist_proxy.id
    http_method             = aws_api_gateway_method.std17_loadlist_proxy_get.http_method
    type                    = "HTTP_PROXY"
    integration_http_method = "GET"
    uri                     = "http://${var.alb_dns_name}:8080/loadlist/{proxy}"

    request_parameters = {
        "integration.request.path.proxy" = "method.request.path.proxy"
    }
}

# ==================================================================
# 배포 / 스테이지 / 커스텀 도메인
resource "aws_api_gateway_deployment" "std17_site_api" {
    rest_api_id = aws_api_gateway_rest_api.std17_site_api.id

    depends_on = [
        aws_api_gateway_integration.std17_company_get,
        aws_api_gateway_integration.std17_student_get,
        aws_api_gateway_integration.std17_docker_get,
        aws_api_gateway_integration.std17_docker_proxy_get,
        aws_api_gateway_integration.std17_api_students_get,
        aws_api_gateway_integration.std17_root_get,
        aws_api_gateway_integration.std17_test_get,
        aws_api_gateway_integration.std17_test_proxy_get,
        aws_api_gateway_integration.std17_score_get,
        aws_api_gateway_integration.std17_score_proxy_get,
        aws_api_gateway_integration.std17_loadlist_proxy_get,
    ]

    lifecycle {
        create_before_destroy = true
    }
}

resource "aws_api_gateway_stage" "std17_prod" {
    deployment_id = aws_api_gateway_deployment.std17_site_api.id
    rest_api_id   = aws_api_gateway_rest_api.std17_site_api.id
    stage_name    = "prod"
}

resource "aws_api_gateway_domain_name" "std17_site" {
    domain_name              = var.domain_name
    regional_certificate_arn = var.acm_certificate_arn

    endpoint_configuration {
        types = ["REGIONAL"]
    }
}

resource "aws_api_gateway_base_path_mapping" "std17_site" {
    api_id      = aws_api_gateway_rest_api.std17_site_api.id
    stage_name  = aws_api_gateway_stage.std17_prod.stage_name
    domain_name = aws_api_gateway_domain_name.std17_site.domain_name
}

resource "aws_route53_record" "std17_site" {
    zone_id = var.hosted_zone_id
    name    = var.domain_name
    type    = "A"

    alias {
        name                   = aws_api_gateway_domain_name.std17_site.regional_domain_name
        zone_id                = aws_api_gateway_domain_name.std17_site.regional_zone_id
        evaluate_target_health = false
    }
}