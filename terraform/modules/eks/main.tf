data "aws_caller_identity" "current" {}

locals {
    admin_arns = length(var.admin_principal_arns) > 0 ? var.admin_principal_arns : [data.aws_caller_identity.current.arn]
}

# ==================================================================
# 1. IAM — EKS 클러스터 / 노드그룹 역할
# ==================================================================

resource "aws_iam_role" "std17_test_eks_cluster_role" {
    name = "std17-test-eks-cluster-role"

    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [{
            Effect    = "Allow"
            Principal = { Service = "eks.amazonaws.com" }
            Action    = "sts:AssumeRole"
        }]
    })

    tags = { Name = "std17-test-eks-cluster-role" }
}

resource "aws_iam_role_policy_attachment" "std17_test_eks_cluster_policy" {
    role       = aws_iam_role.std17_test_eks_cluster_role.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role" "std17_test_eks_node_role" {
    name = "std17-test-eks-node-role"

    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [{
            Effect    = "Allow"
            Principal = { Service = "ec2.amazonaws.com" }
            Action    = "sts:AssumeRole"
        }]
    })

    tags = { Name = "std17-test-eks-node-role" }
}

resource "aws_iam_role_policy_attachment" "std17_test_eks_worker_node_policy" {
    role       = aws_iam_role.std17_test_eks_node_role.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "std17_test_eks_cni_policy" {
    role       = aws_iam_role.std17_test_eks_node_role.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

# 이전 대화에서 확인했던 "ECR pull 권한 필수" 부분 반영
resource "aws_iam_role_policy_attachment" "std17_test_eks_ecr_readonly" {
    role       = aws_iam_role.std17_test_eks_node_role.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# 디버깅용: SSM Session Manager로 노드 접속, kubelet/hostPath 로그 확인
resource "aws_iam_role_policy_attachment" "std17_test_eks_ssm_core" {
    role       = aws_iam_role.std17_test_eks_node_role.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# ==================================================================
# 2. 보안그룹 — 컨트롤플레인 <-> 노드 통신
# ==================================================================

resource "aws_security_group" "std17_test_eks_cluster_sg" {
    name        = "std17-test-eks-cluster-sg"
    vpc_id      = var.vpc_id
    description = "EKS control plane to node communication SG"

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = { Name = "std17-test-eks-cluster-sg" }
}

resource "aws_security_group" "std17_test_eks_node_sg" {
    name        = "std17-test-eks-node-sg"
    vpc_id      = var.vpc_id
    description = "EKS worker node SG"

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = { Name = "std17-test-eks-node-sg" }
}

resource "aws_security_group_rule" "std17_test_cluster_from_node" {
    type                     = "ingress"
    from_port                = 443
    to_port                  = 443
    protocol                 = "tcp"
    security_group_id        = aws_security_group.std17_test_eks_cluster_sg.id
    source_security_group_id = aws_security_group.std17_test_eks_node_sg.id
    description              = "node to cluster API server"
}

resource "aws_security_group_rule" "std17_test_cluster_to_node" {
    type                     = "egress"
    from_port                = 0
    to_port                  = 65535
    protocol                 = "tcp"
    security_group_id        = aws_security_group.std17_test_eks_cluster_sg.id
    source_security_group_id = aws_security_group.std17_test_eks_node_sg.id
    description              = "cluster SG to node SG"
}

resource "aws_security_group_rule" "std17_test_node_from_cluster" {
    type                     = "ingress"
    from_port                = 1025
    to_port                  = 65535
    protocol                 = "tcp"
    security_group_id        = aws_security_group.std17_test_eks_node_sg.id
    source_security_group_id = aws_security_group.std17_test_eks_cluster_sg.id
    description              = "kubelet communication from cluster"
}

resource "aws_security_group_rule" "std17_test_node_https_from_cluster" {
    type                     = "ingress"
    from_port                = 443
    to_port                  = 443
    protocol                 = "tcp"
    security_group_id        = aws_security_group.std17_test_eks_node_sg.id
    source_security_group_id = aws_security_group.std17_test_eks_cluster_sg.id
    description              = "HTTPS response to cluster"
}

resource "aws_security_group_rule" "std17_test_node_to_node" {
    type              = "ingress"
    from_port         = 0
    to_port           = 65535
    protocol          = "-1"
    security_group_id = aws_security_group.std17_test_eks_node_sg.id
    self              = true
    description       = "node to node pod communication"
}

# ==================================================================
# 3. EKS 클러스터
# ==================================================================

resource "aws_eks_cluster" "std17_test_eks" {
    name     = var.cluster_name
    version  = var.cluster_version
    role_arn = aws_iam_role.std17_test_eks_cluster_role.arn

    vpc_config {
        subnet_ids              = var.private_subnet_ids
        security_group_ids      = [aws_security_group.std17_test_eks_cluster_sg.id]
        endpoint_private_access = true
        endpoint_public_access  = var.endpoint_public_access
        public_access_cidrs     = var.endpoint_public_access_cidrs
    }

    access_config {
        authentication_mode = "API"
    }

    depends_on = [aws_iam_role_policy_attachment.std17_test_eks_cluster_policy]

    tags = { Name = var.cluster_name }
}

# ==================================================================
# 4. 관리형 노드그룹 (item 10: t3.small, 최소1/유지1/최대2)
# ==================================================================

resource "aws_eks_node_group" "std17_test_eks_nodegroup" {
    cluster_name    = aws_eks_cluster.std17_test_eks.name
    node_group_name = var.node_group_name
    node_role_arn   = aws_iam_role.std17_test_eks_node_role.arn
    subnet_ids      = var.private_subnet_ids

    instance_types = var.node_instance_types
    capacity_type  = "ON_DEMAND"
    disk_size      = var.node_disk_size

    scaling_config {
        desired_size = var.node_desired_size
        min_size     = var.node_min_size
        max_size     = var.node_max_size
    }

    update_config {
        max_unavailable = 1
    }

    depends_on = [
        aws_iam_role_policy_attachment.std17_test_eks_worker_node_policy,
        aws_iam_role_policy_attachment.std17_test_eks_cni_policy,
        aws_iam_role_policy_attachment.std17_test_eks_ecr_readonly,
    ]

    tags = { Name = var.node_group_name }
}

# ==================================================================
# 5. 코어 애드온 (VPC CNI, CoreDNS, kube-proxy)
# ==================================================================

resource "aws_eks_addon" "std17_test_vpc_cni" {
    cluster_name  = aws_eks_cluster.std17_test_eks.name
    addon_name    = "vpc-cni"
    addon_version = lookup(var.addon_versions, "vpc-cni", null)

    resolve_conflicts_on_create = "OVERWRITE"
    resolve_conflicts_on_update = "OVERWRITE"

    depends_on = [aws_eks_node_group.std17_test_eks_nodegroup]
}

resource "aws_eks_addon" "std17_test_coredns" {
    cluster_name  = aws_eks_cluster.std17_test_eks.name
    addon_name    = "coredns"
    addon_version = lookup(var.addon_versions, "coredns", null)

    resolve_conflicts_on_create = "OVERWRITE"
    resolve_conflicts_on_update = "OVERWRITE"

    depends_on = [aws_eks_node_group.std17_test_eks_nodegroup]
}

resource "aws_eks_addon" "std17_test_kube_proxy" {
    cluster_name  = aws_eks_cluster.std17_test_eks.name
    addon_name    = "kube-proxy"
    addon_version = lookup(var.addon_versions, "kube-proxy", null)

    resolve_conflicts_on_create = "OVERWRITE"
    resolve_conflicts_on_update = "OVERWRITE"

    depends_on = [aws_eks_node_group.std17_test_eks_nodegroup]
}

# ==================================================================
# 6. Access Entry (관리자 권한 부여)
# ==================================================================

resource "aws_eks_access_entry" "std17_test_admin_entry" {
    count = length(local.admin_arns)

    cluster_name  = aws_eks_cluster.std17_test_eks.name
    principal_arn = local.admin_arns[count.index]
    type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "std17_test_admin_policy" {
    count = length(local.admin_arns)

    cluster_name  = aws_eks_cluster.std17_test_eks.name
    principal_arn = local.admin_arns[count.index]
    policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

    access_scope {
        type = "cluster"
    }

    depends_on = [aws_eks_access_entry.std17_test_admin_entry]
}