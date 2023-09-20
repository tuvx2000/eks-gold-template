#############################################
#                  Common                   #
#############################################
tags = {
  Terraform   = "true"
  Environment = "production"
  Project     = "gold-template"
  Cluster     = "gold-template-cluster-CICD"
}
#############################################
#                   VPC          #
#############################################
vpcs = [
  {
    name             = "gold-template-vpc-CICD"
    cidr_block       = "10.30.0.0/16"
    azs              = ["ap-southeast-1a", "ap-southeast-1b"]
    public_subnets   = ["10.30.1.0/24", "10.30.2.0/24"]
    private_subnets  = ["10.30.3.0/24", "10.30.4.0/24"]
    database_subnets = ["10.30.5.0/24", "10.30.6.0/24"]
  }
]
#############################################
#                   EKS                     #
############################################ 
cluster_name = "gold-template-cluster-CICD"
eks_version  = "1.27"
account_id   = "193801652446"