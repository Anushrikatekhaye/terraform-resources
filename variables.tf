############################
# General
############################
variable "aws_region" {
  description = "AWS region."
  type        = string
  default     = "ap-south-1"
}

variable "project" {
  description = "Project name, used in resource names."
  type        = string
  default     = "demo"
}

variable "environment" {
  description = "Environment name."
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "stage", "prod"], var.environment)
    error_message = "environment must be dev, stage or prod."
  }
}

############################
# Network
############################
variable "vpc_cidr" {
  description = "VPC CIDR block."
  type        = string
  default     = "10.0.0.0/16"
}

variable "az_count" {
  description = "Number of availability zones to use (2 is the usual minimum for HA)."
  type        = number
  default     = 2

  validation {
    condition     = var.az_count >= 1 && var.az_count <= 3
    error_message = "az_count must be between 1 and 3."
  }
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDRs, one per AZ."
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "Private subnet CIDRs, one per AZ."
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "enable_nat_gateway" {
  description = "Create NAT gateway(s) for private subnet internet access (billed hourly)."
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "One shared NAT (cheap, dev) or one per AZ (HA, prod)."
  type        = bool
  default     = true
}

############################
# Security
############################
variable "allowed_http_cidrs" {
  description = "CIDRs allowed to reach the web server on 80/443."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "app_port" {
  description = "Port the private app server listens on (reachable only from the web security group)."
  type        = number
  default     = 8080
}

############################
# Compute / storage
############################
variable "instance_type" {
  description = "EC2 instance type."
  type        = string
  default     = "t3.micro"
}

variable "ubuntu_version" {
  description = "Ubuntu LTS version for the AMI."
  type        = string
  default     = "24.04"
}

variable "root_volume_size" {
  description = "Root EBS size in GiB."
  type        = number
  default     = 20
}

variable "data_volume_size" {
  description = "Extra encrypted EBS data volume for the private app server in GiB (0 = none)."
  type        = number
  default     = 10
}
