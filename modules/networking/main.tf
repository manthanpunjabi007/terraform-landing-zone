data "aws_availability_zones" "available" {
  state = "available"
}
data "aws_region" "current" {}

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.name_prefix}-vpc"
  }
}
resource "aws_subnet" "this" {
  for_each = var.subnets

  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value.cidr
  availability_zone = data.aws_availability_zones.available.names[each.value.az_index]

  tags = {
    Name = "${var.name_prefix}-${each.key}"
    Tier = each.value.tier
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.name_prefix}-igw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  tags = {
    Name = "${var.name_prefix}-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  for_each = { for k, v in var.subnets : k => v if v.tier == "public" }

  subnet_id      = aws_subnet.this[each.key].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.name_prefix}-private-rt"
  }
}

resource "aws_route_table" "isolated" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.name_prefix}-isolated-rt"
  }
}

resource "aws_route_table_association" "private" {
  for_each       = { for k, v in var.subnets : k => v if v.tier == "private" }
  subnet_id      = aws_subnet.this[each.key].id
  route_table_id = aws_route_table.private.id
}
resource "aws_route_table_association" "isolated" {
  for_each = { for k, v in var.subnets : k => v if v.tier == "isolated" }

  subnet_id      = aws_subnet.this[each.key].id
  route_table_id = aws_route_table.isolated.id
}

resource "aws_default_route_table" "main" {
  default_route_table_id = aws_vpc.main.default_route_table_id
  tags = {
    Name = "${var.name_prefix}-main-rt-unused"
  }
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${data.aws_region.current.region}.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = [aws_route_table.private.id]

  tags = {
    Name = "${var.name_prefix}-s3-endpoint"
  }
}

resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.main.id

  # Intentionally empty: no ingress, no egress.
  # This group cannot be deleted and is attached to anything that
  # does not specify a security group, so it is stripped to deny-all.

  tags = {
    Name = "${var.name_prefix}-default-sg-locked"
  }
}