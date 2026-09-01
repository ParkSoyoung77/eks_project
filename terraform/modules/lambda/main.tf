resource "aws_api_gateway_rest_api" "site" {
  name = "std00-test-site-api"
}

# S3 정적 웹사이트 엔드포인트 (버킷 리전에 맞게 수정)
locals {
  s3_website_endpoint = "test.domain.class.s3-website.ap-northeast-3.amazonaws.com"
}

# 루트(/) -> index.html
resource "aws_api_gateway_method" "root_get" {
  rest_api_id   = aws_api_gateway_rest_api.site.id
  resource_id   = aws_api_gateway_rest_api.site.root_resource_id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "root_integration" {
  rest_api_id             = aws_api_gateway_rest_api.site.id
  resource_id             = aws_api_gateway_rest_api.site.root_resource_id
  http_method             = aws_api_gateway_method.root_get.http_method
  type                    = "HTTP_PROXY"
  integration_http_method = "GET"
  uri                     = "http://${local.s3_website_endpoint}/index.html"
}

# /company, /student 같은 단일 경로용 모듈화
resource "aws_api_gateway_resource" "path" {
  for_each    = toset(["company", "student"])
  rest_api_id = aws_api_gateway_rest_api.site.id
  parent_id   = aws_api_gateway_rest_api.site.root_resource_id
  path_part   = each.value
}

resource "aws_api_gateway_method" "path_get" {
  for_each      = aws_api_gateway_resource.path
  rest_api_id   = aws_api_gateway_rest_api.site.id
  resource_id   = each.value.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "path_integration" {
  for_each                = aws_api_gateway_resource.path
  rest_api_id             = aws_api_gateway_rest_api.site.id
  resource_id             = each.value.id
  http_method             = aws_api_gateway_method.path_get[each.key].http_method
  type                    = "HTTP_PROXY"
  integration_http_method = "GET"
  uri                     = "http://${local.s3_website_endpoint}/${each.key}.html"
}

# /docker/{proxy+} -> S3 /docker/* 하위 모든 파일 (ex-3.zip 안의 여러 html)
resource "aws_api_gateway_resource" "docker" {
  rest_api_id = aws_api_gateway_rest_api.site.id
  parent_id   = aws_api_gateway_rest_api.site.root_resource_id
  path_part   = "docker"
}

resource "aws_api_gateway_resource" "docker_proxy" {
  rest_api_id = aws_api_gateway_rest_api.site.id
  parent_id   = aws_api_gateway_resource.docker.id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "docker_proxy_get" {
  rest_api_id   = aws_api_gateway_rest_api.site.id
  resource_id   = aws_api_gateway_resource.docker_proxy.id
  http_method   = "GET"
  authorization = "NONE"
  request_parameters = {
    "method.request.path.proxy" = true
  }
}

resource "aws_api_gateway_integration" "docker_proxy_integration" {
  rest_api_id             = aws_api_gateway_rest_api.site.id
  resource_id             = aws_api_gateway_resource.docker_proxy.id
  http_method             = aws_api_gateway_method.docker_proxy_get.http_method
  type                    = "HTTP_PROXY"
  integration_http_method = "GET"
  uri                     = "http://${local.s3_website_endpoint}/docker/{proxy}"
  request_parameters = {
    "integration.request.path.proxy" = "method.request.path.proxy"
  }
}

resource "aws_api_gateway_deployment" "site" {
  rest_api_id = aws_api_gateway_rest_api.site.id
  depends_on = [
    aws_api_gateway_integration.root_integration,
    aws_api_gateway_integration.path_integration,
    aws_api_gateway_integration.docker_proxy_integration,
  ]
}

resource "aws_api_gateway_stage" "prod" {
  deployment_id = aws_api_gateway_deployment.site.id
  rest_api_id   = aws_api_gateway_rest_api.site.id
  stage_name    = "prod"
}