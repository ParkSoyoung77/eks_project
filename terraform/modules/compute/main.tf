resource "aws_s3_bucket" "deploy_artifacts" {
    bucket = "${var.name_prefix}-deploy-artifacts"
    tags   = { Name = "${var.name_prefix}-deploy-artifacts" }
}

resource "aws_s3_bucket_public_access_block" "deploy_artifacts" {
    bucket                  = aws_s3_bucket.deploy_artifacts.id
    block_public_acls       = true
    ignore_public_acls      = true
    block_public_policy     = true
    restrict_public_buckets = true
}

resource "aws_s3_object" "compose_file" {
    bucket       = aws_s3_bucket.deploy_artifacts.id
    key          = "docker-compose.yaml"
    source       = "${path.module}/../../../docker/docker-compose.yaml"
    etag         = filemd5("${path.module}/../../../docker/docker-compose.yaml")
    content_type = "application/x-yaml"
}