terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.19.0"
    }
  }
  backend "s3" {
    bucket = ""
    key    = "vpc-endpoint-peering"
    region = ""
  }
}

provider "aws" {
  region = var.primary.region
  #   alias  = "primary"
  default_tags {
    tags = {
      project = "vpc-endpoint-peering"
    }
  }
}

provider "aws" {
  region = var.secondary.region
  alias  = "secondary"
  default_tags {
    tags = {
      project = "vpc-endpoint-peering"
    }
  }
}

provider "aws" {
  region = var.tertiary.region
  alias  = "tertiary"
  default_tags {
    tags = {
      project = "vpc-endpoint-peering"
    }
  }
}