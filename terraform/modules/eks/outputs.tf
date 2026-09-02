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