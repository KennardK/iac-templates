resource "aws_vpc" "vpc" {
  cidr_block           = var.region_parameters.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.prefix}-vpc"
  }
}

resource "aws_subnet" "private_subnet" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = var.region_parameters.private_subnet_cidr

  tags = {
    Name = "${var.prefix}-private-subnet"
  }
}

resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.vpc.id

  ingress {
    description = "Allow https inbound from primary region and self vpc"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.primary_parameters.vpc_cidr, var.region_parameters.vpc_cidr]
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

resource "aws_vpc_peering_connection" "peer" {
  vpc_id      = aws_vpc.vpc.id
  peer_vpc_id = var.primary_vpc_id
  peer_region = var.primary_parameters.region

  tags = {
    Name = "${var.prefix}-vpc-peering-to-${var.primary_parameters.region}"
  }
}

resource "aws_default_route_table" "rt" {
  default_route_table_id = aws_vpc.vpc.default_route_table_id

  route {
    cidr_block                = var.primary_parameters.vpc_cidr
    vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
  }

  tags = {
    Name = "${var.prefix}-default-route-table"
  }
}

resource "aws_vpc_endpoint" "s3_gateway" {
  count             = contains(var.region_parameters.endpoints, "s3") ? 1 : 0
  vpc_id            = aws_vpc.vpc.id
  service_name      = "com.amazonaws.${var.region_parameters.region}.s3"
  route_table_ids   = [aws_vpc.vpc.default_route_table_id]
  vpc_endpoint_type = "Gateway"

  tags = {
    Name = "${var.prefix}-s3-gateway-endpoint"
  }
}


resource "aws_vpc_endpoint" "s3_interface" {
  count               = contains(var.region_parameters.endpoints, "s3") && var.should_create ? 1 : 0
  vpc_id              = aws_vpc.vpc.id
  service_name        = "com.amazonaws.${var.region_parameters.region}.s3"
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

resource "aws_route53_record" "s3_interface_endpoint_record" {
  count   = contains(var.region_parameters.endpoints, "s3") && var.should_create ? 1 : 0
  zone_id = lookup(var.route53_private_zones, aws_vpc_endpoint.s3_interface[0].dns_entry[2].dns_name)
  name    = aws_vpc_endpoint.s3_interface[0].dns_entry[2].dns_name
  type    = "A"

  alias {
    name                   = replace(aws_vpc_endpoint.s3_interface[0].dns_entry[0].dns_name, "*", "\\052")
    zone_id                = aws_vpc_endpoint.s3_interface[0].dns_entry[0].hosted_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "s3_interface_endpoint_record_asterisk" {
  count   = contains(var.region_parameters.endpoints, "s3") && var.should_create ? 1 : 0
  zone_id = lookup(var.route53_private_zones, aws_vpc_endpoint.s3_interface[0].dns_entry[2].dns_name)
  name    = "*.${aws_vpc_endpoint.s3_interface[0].dns_entry[2].dns_name}"
  type    = "A"

  alias {
    name                   = replace(aws_vpc_endpoint.s3_interface[0].dns_entry[0].dns_name, "*", "\\052")
    zone_id                = aws_vpc_endpoint.s3_interface[0].dns_entry[0].hosted_zone_id
    evaluate_target_health = true
  }
}

resource "aws_vpc_endpoint" "interface_endpoints" {
  for_each = var.should_create ? setsubtract(var.region_parameters.endpoints, ["s3"]) : toset([])

  vpc_id              = aws_vpc.vpc.id
  service_name        = "com.amazonaws.${var.region_parameters.region}.${each.value}"
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

resource "aws_route53_record" "interface_endpoint_records" {
  for_each = var.should_create ? { for endpoint, attributes in aws_vpc_endpoint.interface_endpoints : attributes.dns_entry[2].dns_name => attributes.dns_entry[0] } : {}

  zone_id = lookup(var.route53_private_zones, each.key)
  name    = each.key
  type    = "A"

  alias {
    name                   = each.value.dns_name
    zone_id                = each.value.hosted_zone_id
    evaluate_target_health = true
  }
}