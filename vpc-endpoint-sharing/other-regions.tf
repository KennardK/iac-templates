module "secondary" {
  source = "./modules/network"
  providers = {
    aws = aws.secondary #change this when adding a new region
  }
  should_create         = var.should_create
  prefix                = var.prefix
  primary_parameters    = var.primary
  region_parameters     = var.secondary #change this when adding a new region
  primary_vpc_id        = aws_vpc.vpc.id
  route53_private_zones = local.private_zones_dict
}

module "tertiary" {
  source = "./modules/network"
  providers = {
    aws = aws.tertiary #change this when adding a new region
  }
  should_create         = var.should_create
  prefix                = var.prefix
  primary_parameters    = var.primary
  region_parameters     = var.tertiary #change this when adding a new region
  primary_vpc_id        = aws_vpc.vpc.id
  route53_private_zones = local.private_zones_dict
}