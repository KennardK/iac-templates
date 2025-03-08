variable "should_create" {
  type = bool
}

variable "prefix" {
  type = string
}

variable "primary_parameters" {
  type = object({
    region              = string
    vpc_cidr            = string
    private_subnet_cidr = string
    endpoints           = set(string)
  })
}

variable "region_parameters" {
  type = object({
    region              = string
    vpc_cidr            = string
    private_subnet_cidr = string
    endpoints           = set(string)
  })
}

variable "primary_vpc_id" {
  type        = string
  description = "VPC ID of primary region"
}

variable "route53_private_zones" {
}