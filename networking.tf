data "aws_availability_zones" "available" {}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.1"

  name             = var.vpcs[0].name
  cidr             = var.vpcs[0].cidr_block
  azs              = var.vpcs[0].azs
  public_subnets   = var.vpcs[0].public_subnets
  database_subnets = var.vpcs[0].database_subnets
  private_subnets  = var.vpcs[0].private_subnets

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = var.tags

  igw_tags = {
    "Name" = "gold-template-igw"
  }

  nat_gateway_tags = {
    "Name" = "gold-template-nat"
  }

  nat_eip_tags = merge(
    var.tags,
    {
      "Name" = "gold-template-nat-eip"
    }
  )

  public_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                    = 1
    "Terraform"                                 = true
    "Name"                                      = "gold-template-public-subnet"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"           = 1
    "Terraform"                                 = true
    "Name"                                      = "gold-template-private-subnet"
  }

  database_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"           = 1
    "Terraform"                                 = true
    "Name"                                      = "gold-template-database-subnet"
  }

  public_route_table_tags = merge(
    var.tags,
    {
      "Name" = "gold-template-public-route"
    }
  )
  private_route_table_tags = merge(
    var.tags,
    {
      "Name" = "gold-template-private-route"
    }
  )
  #############################################
  #                 Only-for-VPN              #
  #############################################
  enable_vpn_gateway = true
  amazon_side_asn    = 64512

  customer_gateways = {
    IP1 = {
      bgp_asn    = 65000
      ip_address = "42.116.26.68"
    }
    IP2 = {
      bgp_asn    = 65000
      ip_address = "125.234.252.38"
    }
  }

  #############################################
  #                 Cloudwatch Log            #
  #############################################
  # VPC Flow Logs (Cloudwatch log group and IAM role will be created)

  enable_flow_log                           = true
  create_flow_log_cloudwatch_log_group      = true
  create_flow_log_cloudwatch_iam_role       = true
  flow_log_max_aggregation_interval         = 60
  flow_log_cloudwatch_log_group_name_prefix = "/aws/gold-template-vpc-CICD-flow-logs/"
  flow_log_cloudwatch_log_group_name_suffix = "logs"

}