data "aws_ami" "std17_ubuntu" {
    most_recent = true
    owners      = ["099720109477"]

    filter {
        name   = "name"
        values = ["ubuntu/images/hvm-ssd/ubuntu-noble-22.04-amd64-server-*"]
    }

    filter {
        name   = "virtualization-type"
        values = ["hvm"]
    }
}

# ==================================================================
# 배포 아티팩트 버킷 (docker-compose.yaml, fastapi.env)
resource "aws_s3_bucket" "std17_deploy_artifacts" {
    bucket = "${var.name_prefix}-deploy-artifacts"
    tags = {
        Name = "${var.name_prefix}-deploy-artifacts"
    }
}

resource "aws_s3_bucket_public_access_block" "std17_deploy_artifacts" {
    bucket                  = aws_s3_bucket.std17_deploy_artifacts.id
    block_public_acls       = true
    ignore_public_acls      = true
    block_public_policy     = true
    restrict_public_buckets = true
}

resource "aws_s3_object" "std17_compose_file" {
    bucket       = aws_s3_bucket.std17_deploy_artifacts.id
    key          = "docker-compose.yaml"
    source       = "${path.module}/files/docker-compose.yaml"
    etag         = filemd5("${path.module}/files/docker-compose.yaml")
    content_type = "application/x-yaml"
}

resource "aws_s3_object" "std17_fastapi_env" {
    bucket = aws_s3_bucket.std17_deploy_artifacts.id
    key    = "fastapi.env"
    source = "${path.module}/files/fastapi.env"
    etag   = filemd5("${path.module}/files/fastapi.env")
}

resource "aws_iam_role_policy" "std17_ec2_deploy_bucket_read" {
    name = "${var.name_prefix}-ec2-deploy-bucket-read"
    role = var.ec2_role_name

    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [{
            Effect   = "Allow"
            Action   = ["s3:GetObject"]
            Resource = "${aws_s3_bucket.std17_deploy_artifacts.arn}/*"
        }]
    })
}

# ==================================================================
# 시작 템플릿 / ASG
resource "aws_launch_template" "std17_ec2_app" {
    name_prefix   = "${var.name_prefix}-lt-"
    image_id      = data.aws_ami.std17_ubuntu.id
    instance_type = var.instance_type
    key_name      = var.key_name

    iam_instance_profile {
        name = var.instance_profile_name
    }

    vpc_security_group_ids = [var.security_group_id]

    user_data = base64encode(templatefile("${path.module}/scripts/user_data.sh", {
    ecr_registry       = var.ecr_registry
    deploy_bucket_name = aws_s3_bucket.std17_deploy_artifacts.id
    }))

    tag_specifications {
        resource_type = "instance"
        tags = {
            Name = "${var.name_prefix}-ec2"
        }
    }
}

resource "aws_autoscaling_group" "std17_ec2_asg" {
    name                = "${var.name_prefix}-asg"
    min_size            = 1
    desired_capacity    = 1
    max_size            = 2
    vpc_zone_identifier = var.subnet_ids
    target_group_arns   = [var.alb_target_group_arn]
    health_check_type   = "ELB"

    launch_template {
        id      = aws_launch_template.std17_ec2_app.id
        version = "$Latest"
    }

    tag {
        key                 = "Name"
        value               = "${var.name_prefix}-ec2"
        propagate_at_launch = true
    }
}