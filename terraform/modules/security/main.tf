resource "aws_security_group" "std17_alb_sg" {
    name        = "${var.name_prefix}-alb-sg"
    vpc_id      = var.vpc_id
    description = "ALB SG - HTTP/HTTPS from internet"

    ingress {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port   = 443
        to_port     = 443
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "${var.name_prefix}-alb-sg"
    }
}

# ==================================================================
resource "aws_security_group" "std17_ec2_sg" {
    name        = "${var.name_prefix}-ec2-sg"
    vpc_id      = var.vpc_id
    description = "EC2 docker-compose SG - only from ALB"

    ingress {
        from_port       = 80
        to_port         = 80
        protocol        = "tcp"
        security_groups = [aws_security_group.std17_alb_sg.id]
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "${var.name_prefix}-ec2-sg"
    }
}

# ==================================================================
resource "aws_security_group" "std17_rds_sg" {
    name        = "${var.name_prefix}-rds-sg"
    vpc_id      = var.vpc_id
    description = "RDS SG - MySQL from app tiers only"

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "${var.name_prefix}-rds-sg"
    }
}

# ==================================================================
resource "aws_security_group" "std17_lambda_sg" {
    name        = "${var.name_prefix}-lambda-sg"
    vpc_id      = var.vpc_id
    description = "Lambda SG - RDS Proxy 접근용"

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "${var.name_prefix}-lambda-sg"
    }
}

# lambda -> rds (3306)
resource "aws_security_group_rule" "std17_rds_from_lambda" {
    type                     = "ingress"
    from_port                = 3306
    to_port                  = 3306
    protocol                 = "tcp"
    security_group_id        = aws_security_group.std17_rds_sg.id
    source_security_group_id = aws_security_group.std17_lambda_sg.id
    description              = "lambda to RDS proxy"
}