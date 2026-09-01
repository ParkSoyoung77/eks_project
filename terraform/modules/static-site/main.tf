# std17-test-bucket

locals {
    company_html_path = var.company_html_path != "" ? var.company_html_path : "${path.module}/files/company.html"
    student_html_path = var.student_html_path != "" ? var.student_html_path : "${path.module}/files/student.html"
}

# ── 버킷 1: 회사소개 ──────────────────────────────
resource "aws_s3_bucket" "static_site_1" {
    bucket = var.bucket_name_1  # st00-test-bucket
    tags   = { Name = "${var.name_prefix}-static-site-1" }
}

resource "aws_s3_bucket_website_configuration" "static_site_1" {
    bucket = aws_s3_bucket.static_site_1.id
    index_document {
        suffix = "index.html"
    }
}

resource "aws_s3_bucket_public_access_block" "static_site_1" {
    bucket                  = aws_s3_bucket.static_site_1.id
    block_public_acls       = false
    ignore_public_acls      = false
    block_public_policy     = false
    restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "static_site_1" {
    bucket = aws_s3_bucket.static_site_1.id
    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [{
            Sid       = "PublicReadGetObject"
            Effect    = "Allow"
            Principal = "*"
            Action    = "s3:GetObject"
            Resource  = "${aws_s3_bucket.static_site_1.arn}/*"
        }]
    })
}

resource "aws_s3_object" "site1_index" {
    bucket       = aws_s3_bucket.static_site_1.id
    key          = "index.html"
    source       = local.company_html_path
    etag         = filemd5(local.company_html_path)
    content_type = "text/html"
}

# ── 버킷 2: 교육생정보 ──────────────────────────────
resource "aws_s3_bucket" "static_site_2" {
    bucket = var.bucket_name_2  # 예: st00-test-bucket-2
    tags   = { Name = "${var.name_prefix}-static-site-2" }
}

resource "aws_s3_bucket_website_configuration" "static_site_2" {
    bucket = aws_s3_bucket.static_site_2.id
    index_document {
        suffix = "index.html"
    }
}

resource "aws_s3_bucket_public_access_block" "static_site_2" {
    bucket                  = aws_s3_bucket.static_site_2.id
    block_public_acls       = false
    ignore_public_acls      = false
    block_public_policy     = false
    restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "static_site_2" {
    bucket = aws_s3_bucket.static_site_2.id
    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [{
            Sid       = "PublicReadGetObject"
            Effect    = "Allow"
            Principal = "*"
            Action    = "s3:GetObject"
            Resource  = "${aws_s3_bucket.static_site_2.arn}/*"
        }]
    })
}

resource "aws_s3_object" "site2_index" {
    bucket       = aws_s3_bucket.static_site_2.id
    key          = "index.html"
    source       = local.student_html_path
    etag         = filemd5(local.student_html_path)
    content_type = "text/html"
}