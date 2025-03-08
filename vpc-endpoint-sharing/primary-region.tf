locals {
  region_parameters = {
    secondary = {
      parameters            = var.secondary
      peering_connection_id = module.secondary.peering_connection_id
    }
    tertiary = {
      parameters            = var.tertiary
      peering_connection_id = module.tertiary.peering_connection_id
    }
  }
}

resource "aws_vpc" "vpc" {
  cidr_block           = var.primary.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.prefix}-vpc"
  }
}

resource "aws_subnet" "private_subnet" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = var.primary.private_subnet_cidr

  tags = {
    Name = "${var.prefix}-private-subnet"
  }
}

resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.vpc.id

  ingress {
    description = "Allow https inbound from other regions"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [for name, region_param in local.region_parameters : region_param.parameters.vpc_cidr]
  }

  ingress {
    description = "Allow https inbound from self vpc"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.primary.vpc_cidr]
  }

  egress {
    description = "Allow https outbound to all"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.prefix}-default-sg"
  }
}

resource "aws_vpc_peering_connection_accepter" "peer_accepter" {
  for_each                  = { for name, region_param in local.region_parameters : region_param.parameters.region => region_param.peering_connection_id }
  vpc_peering_connection_id = each.value
  auto_accept               = true

  tags = {
    Name = "${var.prefix}-vpc-peering-to-${each.key}"
  }
}

resource "aws_default_route_table" "rt" {
  default_route_table_id = aws_vpc.vpc.default_route_table_id

  dynamic "route" {
    for_each = { for name, region_param in local.region_parameters : region_param.parameters.vpc_cidr => region_param.peering_connection_id }
    content {
      cidr_block                = route.key
      vpc_peering_connection_id = route.value
    }
  }
  tags = {
    Name = "${var.prefix}-default-route-table"
  }
}

resource "aws_vpc_endpoint" "s3_gateway" {
  count             = contains(var.primary.endpoints, "s3") ? 1 : 0
  vpc_id            = aws_vpc.vpc.id
  service_name      = "com.amazonaws.${var.primary.region}.s3"
  route_table_ids   = [aws_vpc.vpc.default_route_table_id]
  vpc_endpoint_type = "Gateway"

  tags = {
    Name = "${var.prefix}-s3-gateway-endpoint"
  }
}

resource "aws_vpc_endpoint" "s3_interface" {
  count               = contains(var.primary.endpoints, "s3") && var.should_create ? 1 : 0
  vpc_id              = aws_vpc.vpc.id
  service_name        = "com.amazonaws.${var.primary.region}.s3"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = [aws_subnet.private_subnet.id]
  security_group_ids = [
    aws_default_security_group.default.id,
  ]

  tags = {
    Name = "${var.prefix}-s3-interface-endpoint"
  }

  depends_on = [
    aws_vpc_endpoint.s3_gateway,
  ]
}

resource "aws_vpc_endpoint" "interface_endpoints" {
  for_each = var.should_create ? setsubtract(var.primary.endpoints, ["s3"]) : toset([])

  vpc_id              = aws_vpc.vpc.id
  service_name        = "com.amazonaws.${var.primary.region}.${each.value}"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = [aws_subnet.private_subnet.id]
  security_group_ids = [
    aws_default_security_group.default.id,
  ]
  tags = {
    Name = "${var.prefix}-${each.value}-interface-endpoint"
  }
}

locals {
  endpoint_list = flatten([
    for key, region_data in local.region_parameters :
    flatten([
      for endpoint in region_data.parameters.endpoints :
      "${endpoint}.${region_data.parameters.region}.amazonaws.com"
    ])
  ])
}

resource "aws_route53_zone" "private_zones" {
  for_each      = var.should_create ? toset(local.endpoint_list) : toset([])
  name          = each.value
  force_destroy = true
  vpc {
    vpc_id = aws_vpc.vpc.id
  }

  tags = {
    Name = "${var.prefix}-${split(".", each.value)[0]}-private-hosted-zone"
  }
}

locals {
  private_zones_dict = { for name, attributes in aws_route53_zone.private_zones : name => attributes.id }
}