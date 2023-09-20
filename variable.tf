#############################################
#                  Common                   #
#############################################
variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default = {
    Terraform   = "true"
    Project     = "gold-template"
    Environment = "production"
    Cluster     = "gold-template-cluster-CICD",
    owner = "gold-user"
  }
}
variable "env" {
  type    = string
  default = ""
}
#############################################
#                   VPC                     #
#############################################
variable "vpcs" {
  type = list(any)
}
variable "subnet_ids" {
  description = "A list of VPC subnet IDs"
  type        = list(string)
  default     = []
}

#############################################
#                   EKS                     #
#############################################
variable "cluster_name" {
  type    = string
  default = ""
}

variable "eks_version" {
  type    = string
  default = ""
}


variable "account_id" {
  type = string
}

#############################################
#                 Agroapp-UAT-VPC            #
#############################################
variable "vpc_id" {
  type    = string
  default = ""
}
variable "vpc_cidr_block" {
  type    = string
  default = ""
}
variable "private_subnet_ids" {
  type    = string
  default = ""
}
variable "public_route_table_id" {
  type    = string
  default = ""
}
variable "private_route_table_id" {
  type    = string
  default = ""
}