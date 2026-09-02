output "alb_dns_name" {
    description = "ALB DNS 이름"
    value       = aws_lb.std17_alb.dns_name
}

output "alb_zone_id" {
    description = "ALB Route53 Zone ID (alias 레코드용)"
    value       = aws_lb.std17_alb.zone_id
}

output "target_group_arn" {
    description = "ALB 타겟그룹 ARN"
    value       = aws_lb_target_group.std17_ec2_app_tg.arn
}

output "eks_target_group_arn" {
    description = "EKS 타겟그룹 ARN"
    value = aws_lb_target_group.std17_eks_app_tg.arn
}