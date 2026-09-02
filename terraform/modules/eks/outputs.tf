output "cluster_id" {
    value = aws_eks_cluster.std17_test_eks.id
}

output "cluster_endpoint" {
    value = aws_eks_cluster.std17_test_eks.endpoint
}

output "cluster_certificate_authority_data" {
    value = aws_eks_cluster.std17_test_eks.certificate_authority[0].data
}

output "node_security_group_id" {
    value = aws_security_group.std17_test_eks_node_sg.id
}

output "node_role_arn" {
    value = aws_iam_role.std17_test_eks_node_role.arn
}

output "alb_controller_role_arn" {
    value = aws_iam_role.std17_test_alb_controller_role.arn
}

output "oidc_provider_arn" {
    value = aws_iam_openid_connect_provider.std17_test_eks_oidc.arn
}

output "cluster_primary_security_group_id" {
    description = "EKS가 클러스터 생성 시 자동으로 만든 SG (노드에 실제로 붙는 SG)"
    value       = aws_eks_cluster.std17_test_eks.vpc_config[0].cluster_security_group_id
}