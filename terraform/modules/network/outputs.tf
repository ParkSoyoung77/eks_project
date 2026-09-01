output "vpc_id" {
  description = "VPC1 ID"
  value       = aws_vpc.std17_vpc.id
}

output "vpc_cidr" {
  description = "VPC1 CIDR 블록"
  value       = aws_vpc.std17_vpc.cidr_block
}

output "default_rt_id" {
  description = "VPC1 기본 라우팅 테이블 ID"
  value       = aws_default_route_table.std17_vpc_default_rt.id
}

output "public_subnet_ids" {
  description = "퍼블릭 서브넷 ID 리스트"
  value       = aws_subnet.std17_public_subnets[*].id
}

output "private_subnet_ids" {
  description = "프라이빗 서브넷 ID 리스트"
  value       = aws_subnet.std17_private_subnets[*].id
}

output "igw_id" {
  description = "인터넷 게이트웨이 ID"
  value       = aws_internet_gateway.std17_vpc_igw.id
}

output "nat_id" {
  description = "NAT 게이트웨이 ID"
  value       = aws_nat_gateway.std17_nat.id
}

output "public_rt_id" {
  description = "퍼블릭 라우팅 테이블 ID"
  value       = aws_route_table.std17_vpc_public_rt.id
}

output "private_rt_id" {
  description = "프라이빗 라우팅 테이블 ID"
  value       = aws_route_table.std17_vpc_private_rt.id
}