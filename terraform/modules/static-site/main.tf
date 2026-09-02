locals {
    company_html_path = var.company_html_path != "" ? var.company_html_path : "${path.module}/files/company.html"
    student_html_path = var.student_html_path != "" ? var.student_html_path : "${path.module}/files/student.html"
}

# ==================================================================
# 1번 S3 (회사소개)
resource "aws_s3_bucket" "std17_static_site_1" {
    bucket = var.bucket_name_1
    tags = {
        Name = "${var.name_prefix}-static-site-1"
    }
}

resource "aws_s3_bucket_website_configuration" "std17_static_site_1" {
    bucket = aws_s3_bucket.std17_static_site_1.id

    index_document {
        suffix = "index.html"
    }
}

resource "aws_s3_bucket_public_access_block" "std17_static_site_1" {
    bucket                  = aws_s3_bucket.std17_static_site_1.id
    block_public_acls       = false
    ignore_public_acls      = false
    block_public_policy     = false
    restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "std17_static_site_1" {
    bucket = aws_s3_bucket.std17_static_site_1.id
    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [{
            Sid       = "PublicReadGetObject"
            Effect    = "Allow"
            Principal = "*"
            Action    = "s3:GetObject"
            Resource  = "${aws_s3_bucket.std17_static_site_1.arn}/*"
        }]
    })
    depends_on = [aws_s3_bucket_public_access_block.std17_static_site_1]
}

resource "aws_s3_object" "std17_static_site_1_index" {
    bucket       = aws_s3_bucket.std17_static_site_1.id
    key          = "index.html"
    source       = local.company_html_path
    etag         = filemd5(local.company_html_path)
    content_type = "text/html"
}

# ==================================================================
# 2번 S3 (교육생정보)
resource "aws_s3_bucket" "std17_static_site_2" {
    bucket = var.bucket_name_2
    tags = {
        Name = "${var.name_prefix}-static-site-2"
    }
}

resource "aws_s3_bucket_website_configuration" "std17_static_site_2" {
    bucket = aws_s3_bucket.std17_static_site_2.id

    index_document {
        suffix = "index.html"
    }
}

resource "aws_s3_bucket_public_access_block" "std17_static_site_2" {
    bucket                  = aws_s3_bucket.std17_static_site_2.id
    block_public_acls       = false
    ignore_public_acls      = false
    block_public_policy     = false
    restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "std17_static_site_2" {
    bucket = aws_s3_bucket.std17_static_site_2.id
    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [{
            Sid       = "PublicReadGetObject"
            Effect    = "Allow"
            Principal = "*"
            Action    = "s3:GetObject"
            Resource  = "${aws_s3_bucket.std17_static_site_2.arn}/*"
        }]
    })
    depends_on = [aws_s3_bucket_public_access_block.std17_static_site_2]
}

resource "aws_s3_object" "std17_static_site_2_index" {
    bucket       = aws_s3_bucket.std17_static_site_2.id
    key          = "index.html"
    source       = local.student_html_path
    etag         = filemd5(local.student_html_path)
    content_type = "text/html"
}