output "static_address_1" {
    value = "http://${aws_s3_bucket_website_configuration.static_site_1.website_endpoint}"
}

output "static_address_2" {
    value = "http://${aws_s3_bucket_website_configuration.static_site_2.website_endpoint}"
}