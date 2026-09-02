output "certificate_arn" {
    description = "검증 완료된 ACM 인증서 ARN"
    value       = aws_acm_certificate_validation.std17_site_cert.certificate_arn
}