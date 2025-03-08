variable "should_create" {
  type = bool
}

variable "prefix" {
  type = string
}

variable "primary" {
  type = object({
    region              = string
    vpc_cidr            = string
    private_subnet_cidr = string
    endpoints           = set(string)
  })
}

variable "secondary" {
  type = object({
    region              = string
    vpc_cidr            = string
    private_subnet_cidr = string
    endpoints           = set(string)
  })
}

variable "tertiary" {
  type = object({
    region              = string
    vpc_cidr            = string
    private_subnet_cidr = string
    endpoints           = set(string)
  })
}
