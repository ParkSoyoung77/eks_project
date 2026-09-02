output "static_address_1" {
    description = "정적 주소 1"
    value       = "http://${aws_s3_bucket_website_configuration.std17_static_site_1.website_endpoint}"
}

output "static_address_2" {
    description = "정적 주소 2"
    value       = "http://${aws_s3_bucket_website_configuration.std17_static_site_2.website_endpoint}"
}