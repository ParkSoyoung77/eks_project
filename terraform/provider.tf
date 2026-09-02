provider "aws" {
    # 리전: 오사카(AZ 3개)
    region = var.aws_region

    default_tags {
        tags = {
            Owner    = "std17-test"
            Class    = "bipa17"
            ManageBy = "Terraform"
        }
    }
}

# ==================================================================
# EKS 클러스터 인증 토큰 (kubernetes provider용)
# ==================================================================
data "aws_eks_cluster_auth" "std17_eks_auth" {
    name = module.eks.cluster_id
}

provider "kubernetes" {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.std17_eks_auth.token
}

provider "helm" {
    kubernetes {
        host                   = module.eks.cluster_endpoint
        cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
        token                  = data.aws_eks_cluster_auth.std17_eks_auth.token
    }
}