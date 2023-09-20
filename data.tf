data "aws_eks_cluster_auth" "this" {
  name = module.eks.eks_cluster_id
}
data "aws_partition" "current" {}
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}