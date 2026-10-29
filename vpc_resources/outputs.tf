output "vpc_id" {
  description = "VPC ID."
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs."
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs."
  value       = module.vpc.private_subnet_ids
}

output "nat_public_ips" {
  description = "NAT gateway public IPs."
  value       = module.vpc.nat_public_ips
}

output "web_public_ip" {
  description = "Public IP of the web server."
  value       = aws_instance.web.public_ip
}

output "web_instance_id" {
  description = "Web instance ID."
  value       = aws_instance.web.id
}

output "app_instance_id" {
  description = "App instance ID (private)."
  value       = aws_instance.app.id
}

output "ssm_connect_web" {
  description = "Shell access to the web server (no SSH)."
  value       = "aws ssm start-session --target ${aws_instance.web.id} --region ${var.aws_region}"
}

output "ssm_connect_app" {
  description = "Shell access to the private app server (no SSH)."
  value       = "aws ssm start-session --target ${aws_instance.app.id} --region ${var.aws_region}"
}
