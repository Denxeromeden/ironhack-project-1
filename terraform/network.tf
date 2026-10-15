locals {
  az_set = coalesce(var.az, [data.aws_availability_zones.available.names[0], data.aws_availability_zones.available.names[1]])
  pairs  = tolist(setproduct(local.az_set, var.subnet_list))
  subnets_map = {
    for index, pair in local.pairs :
    "${pair[0]}-${pair[1]}" => {
      az     = pair[0]
      prefix = pair[1]
      cidr   = cidrsubnet(var.vpc_cidr, 8, index)
    }
  }
}

resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr
  instance_tenancy     = var.tenancy
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "vpc-${var.unique_id}"
  }
}

resource "aws_subnet" "subnets" {
  for_each          = local.subnets_map
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az
  tags = {
    Name        = "${each.value.prefix}-subnet-${each.value.az}-${var.unique_id}"
    Environment = var.env_tag
    ManagedBy   = "Terraform"
    Owner       = var.unique_id
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "InternetGateway-${var.unique_id}"
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "PublicRouteTable-${var.unique_id}"
  }
}

resource "aws_route" "igw" {
  route_table_id         = aws_route_table.public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public_rt_assoc" {
  for_each       = { for name, config in aws_subnet.subnets : name => config if startswith(config.tags.Name, var.subnet_list[3]) }
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_nat_gateway" "nat" {
  availability_mode = "regional"
  vpc_id            = aws_vpc.vpc.id
  tags = {
    Name = "NAT-${var.unique_id}"
  }

  depends_on = [aws_internet_gateway.igw]
}

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "PrivateRouteTable-${var.unique_id}"
  }
  depends_on = [aws_route_table_association.public_rt_assoc]
}

resource "aws_route" "nat" {
  route_table_id         = aws_route_table.private_rt.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat.id
}

resource "aws_route_table_association" "private_rt_assoc" {
  for_each       = { for name, config in aws_subnet.subnets : name => config if(!startswith(config.tags.Name, var.subnet_list[3])) }
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private_rt.id
  depends_on     = [aws_route.nat, aws_nat_gateway.nat]
}