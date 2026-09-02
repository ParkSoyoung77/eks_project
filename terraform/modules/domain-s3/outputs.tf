output "website_endpoint" {
    description = "S3 정적 웹사이트 엔드포인트"
    value       = aws_s3_bucket_website_configuration.std17_site_bucket.website_endpoint
}

output "bucket_id" {
    description = "S3 버킷 이름"
    value       = aws_s3_bucket.std17_site_bucket.id
}