resource "aws_acm_certificate" "std17_site_cert" {
    domain_name       = var.domain_name
    validation_method = "DNS"

    tags = {
        Name = "${var.name_prefix}-acm-cert"
    }

    lifecycle {
        create_before_destroy = true
    }
}

resource "aws_route53_record" "std17_cert_validation" {
    for_each = {
        for dvo in aws_acm_certificate.std17_site_cert.domain_validation_options : dvo.domain_name => {
            name   = dvo.resource_record_name
            record = dvo.resource_record_value
            type   = dvo.resource_record_type
        }
    }

    zone_id = var.hosted_zone_id
    name    = each.value.name
    type    = each.value.type
    records = [each.value.record]
    ttl     = 60
}

resource "aws_acm_certificate_validation" "std17_site_cert" {
    certificate_arn         = aws_acm_certificate.std17_site_cert.arn
    validation_record_fqdns = [for r in aws_route53_record.std17_cert_validation : r.fqdn]
}