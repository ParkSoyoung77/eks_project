output "invoke_url" {
    description = "REST API 커스텀 도메인 URL"
    value       = "https://${aws_api_gateway_domain_name.std17_site.domain_name}"
}