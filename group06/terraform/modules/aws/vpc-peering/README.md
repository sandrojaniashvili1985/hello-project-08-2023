# VPC Peering Terraform module
Terraform module which creates VPC Peering on AWS.

## Usage
```hcl-terraform
module "vpc_peering" {
  source = "..."

  providers = {
    aws.requester = "aws"
    aws.accepter  = "aws"
  }

  requester_vpc_id                 = "vpc-12345abcde1648d65"
  requester_route_table_ids        = ["rtb-12345abcde1648d65", "rtb-89123456781234567"]

  accepter_vpc_id                 = "vpc-1648d65abcde12345"
  accepter_route_table_ids        = ["rtb-1648d65abcde12345", "rtb-12345678912345678"]
  accepter_region                 = "us-east-1"

  tags = {
    Environment = "Foo"
    Owner = "Bar"
  }
}
```

## Providers
If you are peering VPCs in different accounts you need to pass the correct AWS providers for `requester` and `accepter`
