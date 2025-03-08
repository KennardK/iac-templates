should_create = false

prefix = "myprefix"

primary = {
  region              = "ap-northeast-1"
  vpc_cidr            = "10.0.0.0/16"
  private_subnet_cidr = "10.0.0.0/24"
  endpoints           = ["ssm", "ssmmessages", "ec2", "ec2messages"]
}

secondary = {
  region              = "us-east-1"
  vpc_cidr            = "10.1.0.0/16"
  private_subnet_cidr = "10.1.0.0/24"
  endpoints           = ["ssm"]
}

tertiary = {
  region              = "us-west-2"
  vpc_cidr            = "10.2.0.0/16"
  private_subnet_cidr = "10.2.0.0/24"
  endpoints           = ["s3"]
}