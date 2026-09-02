# vpc
resource "aws_vpc" "std17_vpc" {
    cidr_block           = var.vpc_cidr
    enable_dns_hostnames = true
    enable_dns_support   = true
    tags = {
        Name = "${var.name_prefix}-vpc"
    }
}

resource "aws_default_route_table" "std17_vpc_default_rt" {
    default_route_table_id = aws_vpc.std17_vpc.default_route_table_id
    tags = {
        Name = "${var.name_prefix}-vpc-default-rt"
    }
}

# ==================================================================
# public subnets
resource "aws_subnet" "std17_public_subnets" {
    count                                        = 3
    vpc_id                                       = aws_vpc.std17_vpc.id
    cidr_block                                   = "10.0.${count.index + 1}.0/24"
    availability_zone                            = var.azs[count.index]
    map_public_ip_on_launch                      = true
    enable_resource_name_dns_a_record_on_launch  = true
    private_dns_hostname_type_on_launch          = "ip-name"
    tags = {
        Name = "${var.name_prefix}-public${count.index + 1}-subnet"
    }
}

# IGW
resource "aws_internet_gateway" "std17_vpc_igw" {
    vpc_id = aws_vpc.std17_vpc.id
    tags = {
        Name = "${var.name_prefix}-vpc-igw"
    }
}

# public rt
resource "aws_route_table" "std17_vpc_public_rt" {
    vpc_id = aws_vpc.std17_vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.std17_vpc_igw.id
    }

    tags = {
        Name = "${var.name_prefix}-vpc-public-rt"
    }
}

resource "aws_route_table_association" "std17_vpc_public_rt_assoc" {
    count          = 3
    route_table_id = aws_route_table.std17_vpc_public_rt.id
    subnet_id      = aws_subnet.std17_public_subnets[count.index].id
}

# ==================================================================
# private subnets
resource "aws_subnet" "std17_private_subnets" {
    count             = 3
    vpc_id            = aws_vpc.std17_vpc.id
    cidr_block        = "10.0.${count.index + 11}.0/24"
    availability_zone = var.azs[count.index]
    tags = {
        Name = "${var.name_prefix}-private${count.index + 1}-subnet"
    }
}

# EIP 할당
resource "aws_eip" "std17_nat_eip" {
    domain = "vpc"
    tags = {
        Name = "${var.name_prefix}-nat-eip"
    }
}

# NAT 게이트웨이
resource "aws_nat_gateway" "std17_nat" {
    allocation_id = aws_eip.std17_nat_eip.id
    subnet_id     = aws_subnet.std17_public_subnets[0].id
    depends_on    = [aws_internet_gateway.std17_vpc_igw]
    tags = {
        Name = "${var.name_prefix}-nat"
    }
}

# 프라이빗 라우팅 테이블
resource "aws_route_table" "std17_vpc_private_rt" {
    vpc_id = aws_vpc.std17_vpc.id

    route {
        cidr_block     = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.std17_nat.id
    }

    tags = {
        Name = "${var.name_prefix}-vpc-private-rt"
    }
}

resource "aws_route_table_association" "std17_vpc_private_rt_assoc" {
    count          = 3
    route_table_id = aws_route_table.std17_vpc_private_rt.id
    subnet_id      = aws_subnet.std17_private_subnets[count.index].id
}

# ==================================================================
# eks 전용 private subnets
resource "aws_subnet" "std17_eks_private_subnets" {
    count             = 3
    vpc_id            = aws_vpc.std17_vpc.id
    cidr_block        = "10.0.${count.index + 21}.0/24"
    availability_zone = var.azs[count.index]
    tags = {
        Name                              = "${var.name_prefix}-eks-private${count.index + 1}-subnet"
        "kubernetes.io/role/internal-elb" = "1"
    }
}

# eks 전용 라우팅 테이블
resource "aws_route_table" "std17_vpc_eks_private_rt" {
    vpc_id = aws_vpc.std17_vpc.id

    route {
        cidr_block     = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.std17_nat.id
    }

    tags = {
        Name = "${var.name_prefix}-vpc-eks-private-rt"
    }
}

resource "aws_route_table_association" "std17_vpc_eks_private_rt_assoc" {
    count          = 3
    route_table_id = aws_route_table.std17_vpc_eks_private_rt.id
    subnet_id      = aws_subnet.std17_eks_private_subnets[count.index].id
}

# ==================================================================
# S3 Gateway Endpoint (ECR 이미지 pull, S3 배포파일 접근 최적화)
data "aws_region" "current" {}

resource "aws_vpc_endpoint" "std17_s3_gateway" {
    vpc_id            = aws_vpc.std17_vpc.id
    service_name = "com.amazonaws.${data.aws_region.current.region}.s3"
    vpc_endpoint_type = "Gateway"

    route_table_ids = [
        aws_route_table.std17_vpc_private_rt.id,
        aws_route_table.std17_vpc_eks_private_rt.id,
    ]

    tags = {
        Name = "${var.name_prefix}-s3-gateway-endpoint"
    }
}