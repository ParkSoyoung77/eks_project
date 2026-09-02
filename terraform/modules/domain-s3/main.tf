locals {
    docker_home_html_path = var.index_html_path != "" ? var.index_html_path : "${path.module}/files/index.html"
    company_html_path     = var.company_html_path != "" ? var.company_html_path : "${path.module}/files/company.html"
    student_html_path     = var.student_html_path != "" ? var.student_html_path : "${path.module}/files/student.html"

    docker_pages = {
        "docker/docker-install.html" = "${path.module}/files/docker-install.html"
        "docker/docker-build.html"   = "${path.module}/files/docker-build.html"
        "docker/docker-command.html" = "${path.module}/files/docker-command.html"
        "docker/docker-compose.html" = "${path.module}/files/docker-compose.html"
        "docker/docker-swarm.html"   = "${path.module}/files/docker-swarm.html"
    }
}

# ==================================================================
resource "aws_s3_bucket" "std17_site_bucket" {
    bucket = var.bucket_name
    tags = {
        Name = "${var.name_prefix}-site-bucket"
    }
}

resource "aws_s3_bucket_website_configuration" "std17_site_bucket" {
    bucket = aws_s3_bucket.std17_site_bucket.id

    index_document {
        suffix = "index.html"
    }
}

resource "aws_s3_bucket_public_access_block" "std17_site_bucket" {
    bucket                  = aws_s3_bucket.std17_site_bucket.id
    block_public_acls       = false
    ignore_public_acls      = false
    block_public_policy     = false
    restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "std17_site_bucket" {
    bucket = aws_s3_bucket.std17_site_bucket.id
    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [{
            Sid       = "PublicReadGetObject"
            Effect    = "Allow"
            Principal = "*"
            Action    = "s3:GetObject"
            Resource  = "${aws_s3_bucket.std17_site_bucket.arn}/*"
        }]
    })
}

# ==================================================================
resource "aws_s3_object" "std17_docker_home" {
    bucket       = aws_s3_bucket.std17_site_bucket.id
    key          = "docker/index.html"
    source       = local.docker_home_html_path
    etag         = filemd5(local.docker_home_html_path)
    content_type = "text/html"
}

resource "aws_s3_object" "std17_docker_pages" {
    for_each     = local.docker_pages
    bucket       = aws_s3_bucket.std17_site_bucket.id
    key          = each.key
    source       = each.value
    etag         = filemd5(each.value)
    content_type = "text/html"
}

resource "aws_s3_object" "std17_company_html" {
    bucket       = aws_s3_bucket.std17_site_bucket.id
    key          = "company.html"
    source       = local.company_html_path
    etag         = filemd5(local.company_html_path)
    content_type = "text/html"
}

resource "aws_s3_object" "std17_student_html" {
    bucket       = aws_s3_bucket.std17_site_bucket.id
    key          = "student.html"
    source       = local.student_html_path
    etag         = filemd5(local.student_html_path)
    content_type = "text/html"
}