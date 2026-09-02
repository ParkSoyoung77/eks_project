resource "aws_lb" "std17_alb" {
    name               = "${var.name_prefix}-alb"
    internal           = false
    load_balancer_type = "application"
    security_groups    = [var.security_group_id]
    subnets            = var.public_subnet_ids

    tags = {
        Name = "${var.name_prefix}-alb"
    }
}

resource "aws_lb_target_group" "std17_ec2_app_tg" {
    name        = "${var.name_prefix}-tg"
    port        = 80
    protocol    = "HTTP"
    vpc_id      = var.vpc_id
    target_type = "instance"

    health_check {
        path                = "/"
        healthy_threshold   = 2
        unhealthy_threshold = 5
        interval            = 30
        timeout             = 5
    }

    tags = {
        Name = "${var.name_prefix}-tg"
    }
}

resource "aws_lb_listener" "std17_http" {
    load_balancer_arn = aws_lb.std17_alb.arn
    port              = 80
    protocol          = "HTTP"

    default_action {
        type = "redirect"
        redirect {
            port        = "443"
            protocol    = "HTTPS"
            status_code = "HTTP_301"
        }
    }
}

resource "aws_lb_listener" "std17_https" {
    load_balancer_arn = aws_lb.std17_alb.arn
    port              = 443
    protocol          = "HTTPS"
    ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
    certificate_arn   = var.acm_certificate_arn

    default_action {
        type             = "forward"
        target_group_arn = aws_lb_target_group.std17_ec2_app_tg.arn
    }
}

resource "aws_lb_listener" "std17_internal_proxy" {
    load_balancer_arn = aws_lb.std17_alb.arn
    port              = 8080
    protocol          = "HTTP"

    default_action {
        type             = "forward"
        target_group_arn = aws_lb_target_group.std17_ec2_app_tg.arn
    }
}

resource "aws_lb_listener_rule" "std17_internal_eks_path" {
    listener_arn = aws_lb_listener.std17_internal_proxy.arn
    priority     = 10

    action {
        type             = "forward"
        target_group_arn = aws_lb_target_group.std17_eks_app_tg.arn
    }

    condition {
        path_pattern {
            values = ["/test", "/test/*"]
        }
    }
}

# ==================================================================
# EKS 전용 타겟그룹 (instance 타겟, NodePort 30080)
resource "aws_lb_target_group" "std17_eks_app_tg" {
    name        = "${var.name_prefix}-eks-tg"
    port        = 30080
    protocol    = "HTTP"
    vpc_id      = var.vpc_id
    target_type = "instance"

    health_check {
        path = "/"
        port = "30080"
    }

    tags = { Name = "${var.name_prefix}-eks-tg" }
}

resource "aws_lb_listener_rule" "std17_eks_path" {
    listener_arn = aws_lb_listener.std17_https.arn
    priority     = 10

    action {
        type             = "forward"
        target_group_arn = aws_lb_target_group.std17_eks_app_tg.arn
    }

    condition {
        path_pattern {
            values = ["/test", "/test/*"]
        }
    }
}