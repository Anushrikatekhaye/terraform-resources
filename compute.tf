############################
# Ubuntu AMI (Canonical's official SSM parameter)
############################
data "aws_ssm_parameter" "ubuntu_ami" {
  name = "/aws/service/canonical/ubuntu/server/${var.ubuntu_version}/stable/current/amd64/hvm/ebs-gp3/ami-id"
}

############################
# IAM: SSM Session Manager access (no SSH keys, no port 22)
############################
data "aws_iam_policy_document" "ec2_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ec2" {
  name               = "${local.name}-ec2-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume.json
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2" {
  name = "${local.name}-ec2-profile"
  role = aws_iam_role.ec2.name
}

############################
# Web server: Ubuntu in the PUBLIC subnet
############################
resource "aws_instance" "web" {
  ami                         = nonsensitive(data.aws_ssm_parameter.ubuntu_ami.value)
  instance_type               = var.instance_type
  subnet_id                   = module.vpc.public_subnet_ids[0]
  vpc_security_group_ids      = [aws_security_group.web.id]
  iam_instance_profile        = aws_iam_instance_profile.ec2.name
  associate_public_ip_address = true
  ebs_optimized               = true

  user_data = <<-EOT
    #!/bin/bash
    set -eux
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -y
    apt-get install -y nginx
    systemctl enable --now nginx
  EOT

  user_data_replace_on_change = true

  # IMDSv2 only
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  root_block_device {
    volume_size           = var.root_volume_size
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  tags = { Name = "${local.name}-web" }

  # The instance needs the NAT/IGW routes before it can install packages
  depends_on = [module.vpc]
}

############################
# App server: Ubuntu in the PRIVATE subnet (internet only through NAT)
############################
resource "aws_instance" "app" {
  ami                    = nonsensitive(data.aws_ssm_parameter.ubuntu_ami.value)
  instance_type          = var.instance_type
  subnet_id              = module.vpc.private_subnet_ids[0]
  vpc_security_group_ids = [aws_security_group.app.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2.name
  ebs_optimized          = true

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  root_block_device {
    volume_size           = var.root_volume_size
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  tags = { Name = "${local.name}-app" }

  depends_on = [module.vpc]
}

############################
# Extra encrypted data volume for the app server
############################
resource "aws_ebs_volume" "app_data" {
  count = var.data_volume_size > 0 ? 1 : 0

  availability_zone = aws_instance.app.availability_zone
  size              = var.data_volume_size
  type              = "gp3"
  encrypted         = true

  tags = { Name = "${local.name}-app-data" }
}

resource "aws_volume_attachment" "app_data" {
  count = var.data_volume_size > 0 ? 1 : 0

  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.app_data[0].id
  instance_id = aws_instance.app.id
}
