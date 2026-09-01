output "cluster_name" {
    value = aws_eks_cluster.std17_test_eks.name
}

output "cluster_endpoint" {
    value = aws_eks_cluster.std17_test_eks.endpoint
}

output "cluster_ca_certificate" {
    value = aws_eks_cluster.std17_test_eks.certificate_authority[0].data
}

output "node_security_group_id" {
    value = aws_security_group.std17_test_eks_node_sg.id
}

output "node_role_arn" {
    value = aws_iam_role.std17_test_eks_node_role.arn
}