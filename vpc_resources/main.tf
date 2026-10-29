data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  name = "${var.project}-${var.environment}"
  azs  = slice(data.aws_availability_zones.available.names, 0, var.az_count)
}

module "vpc" {
  source = "./modules/vpc"

  name                 = local.name
  vpc_cidr             = var.vpc_cidr
  azs                  = local.azs
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  enable_nat_gateway   = var.enable_nat_gateway
  single_nat_gateway   = var.single_nat_gateway
}

# Fail early if the subnet lists don't match the number of AZs
check "subnet_counts" {
  assert {
    condition = (
      length(var.public_subnet_cidrs) == var.az_count &&
      length(var.private_subnet_cidrs) == var.az_count
    )
    error_message = "public_subnet_cidrs and private_subnet_cidrs must each have exactly az_count entries."
  }
}
