# AWS VPC with Terraform

A reusable VPC module plus a small root config that proves it works: a public Ubuntu web server and a private Ubuntu app server.

## Architecture

```
                    Internet
                       |
                [Internet Gateway]
                       |
     +-----------------+------------------+
     |  VPC 10.0.0.0/16                   |
     |                                    |
     |  Public subnets (AZ a, AZ b)       |
     |   - route 0.0.0.0/0 -> IGW         |
     |   - NAT gateway(s), Ubuntu web     |
     |            |                       |
     |  Private subnets (AZ a, AZ b)      |
     |   - route 0.0.0.0/0 -> NAT         |
     |   - Ubuntu app + encrypted EBS     |
     +------------------------------------+
```

## Layout

| Path | Purpose |
|---|---|
| `modules/vpc/` | Reusable module: VPC, subnets, IGW, NAT, route tables, S3 endpoint, flow logs |
| `main.tf` | Calls the module, picks AZs, validates subnet counts |
| `security.tf` | Web SG (80/443) and app SG (app port, only from web SG) |
| `compute.tf` | Ubuntu AMI lookup, SSM IAM role, web + app instances, encrypted data volume |
| `variables.tf`, `outputs.tf`, `versions.tf` | Inputs, outputs, provider pinning, backend |
| `terraform.tfvars.example` | Copy to `terraform.tfvars` |

## Best practices applied

- Module for the network layer so it can be reused per environment
- Pinned Terraform and provider versions, remote-state backend block ready
- Subnets spread across AZs; one route table per private subnet
- `single_nat_gateway` toggle: shared NAT for dev, one NAT per AZ for prod
- Default security group has all rules removed
- App tier accepts traffic only from the web tier security group
- No SSH: shell access through SSM Session Manager
- IMDSv2 required, all EBS volumes encrypted
- Free S3 gateway endpoint to keep S3 traffic off the NAT
- VPC flow logs to CloudWatch with 30-day retention
- Consistent naming (`<project>-<env>-<resource>`) and provider `default_tags`

## Usage

```bash
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform fmt -recursive
terraform validate
terraform plan -out=tfplan
terraform apply tfplan

# test
curl http://$(terraform output -raw web_public_ip)
terraform output ssm_connect_app    # run the printed command

# clean up (NAT gateways bill hourly)
terraform destroy
```

## Costs

NAT gateways cost roughly $0.045/hour each plus data processing, so run `terraform destroy` when you finish practicing. Set `enable_nat_gateway = false` if you only need public subnets.

## Ideas for next steps

- Add network ACLs for a second layer of defence
- Add SSM/ECR interface endpoints so private instances need no NAT
- Put the web tier behind an ALB and the app tier in an Auto Scaling group
- Add `tflint` and `checkov` to a CI pipeline
