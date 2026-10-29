variable "name" {
  description = "Name prefix for all VPC resources (e.g. demo-dev)."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block of the VPC."
  type        = string

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "vpc_cidr must be a valid CIDR block, e.g. 10.0.0.0/16."
  }
}

variable "azs" {
  description = "Availability zones to use. One public and one private subnet is created per AZ."
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets (same length as azs)."
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets (same length as azs)."
  type        = list(string)
}

variable "enable_nat_gateway" {
  description = "Create NAT gateway(s) so private subnets get outbound internet."
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "true = one shared NAT (cheap, dev). false = one NAT per AZ (highly available, prod)."
  type        = bool
  default     = true
}

variable "enable_s3_endpoint" {
  description = "Create a free S3 gateway endpoint for the private subnets."
  type        = bool
  default     = true
}

variable "enable_flow_logs" {
  description = "Send VPC flow logs to CloudWatch Logs."
  type        = bool
  default     = true
}

variable "flow_log_retention_days" {
  description = "Retention of the flow log group in days."
  type        = number
  default     = 30
}

variable "tags" {
  description = "Extra tags added to every resource."
  type        = map(string)
  default     = {}
}
