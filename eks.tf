locals {
  # Used to determine correct partition (i.e. - `aws`, `aws-gov`, `aws-cn`, etc.)
  partition = data.aws_partition.current.partition
  node_tags = {
    "Name" = "gold-template-cluster-CICD",
    "owner" = "gold-user"
  }
}

#############################################
#                   EKS                     #
#############################################
module "eks" {
  source = "github.com/aws-ia/terraform-aws-eks-blueprints?ref=v4.32.1"

  # EKS CLUSTER
  cluster_name    = var.cluster_name
  cluster_version = var.eks_version

  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = slice(tolist(module.vpc.private_subnets), 0, 2)

  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = true

  enable_irsa = true

  tags = merge(
    {"owner" = "gold-user"}
  )
  # List of map_users on aws-auth configmap
  map_users = [
    {
      userarn  = "arn:aws:iam::055475569617:user/gold-userdmin"      # The ARN of the IAM user to add.
      username = "eksadmin"                                    # The user name within Kubernetes to map to the IAM role
      groups   = ["system:masters"]                            # A list of groups within Kubernetes to which the role is mapped; Checkout K8s Role and Rolebindings
    }
  ]

  ##EKS MANAGED NODE GROUPS

  managed_node_groups = {
    gold-template-nodegroup = {
      node_group_name = "gold-template-nodegroup"
      instance_types  = ["t3.medium"]
      min_size        = 1
      desired_size    = 1
      max_size        = 2
      capacity_type   = "ON_DEMAND"

      create_iam_role = false
      iam_role_arn    = aws_iam_role.gold-template_nodegroup.arn

      create_launch_template = true
      remote_access          = false
      ec2_ssh_key            = ""
      ssh_security_group_id  = ""
      enable_monitoring      = false

      block_device_mappings = [
        {
          device_name           = "/dev/xvda"
          volume_type           = "gp3"
          volume_size           = 100
          delete_on_termination = true
        }
      ]

      additional_tags = merge(
        var.tags,
        local.node_tags,
        
      )

      launch_template_tags = merge(
        var.tags,
        local.node_tags
      )
    }
  }

  node_security_group_additional_rules = {
    # Extend node-to-node security group rules. Recommended and required for the Add-ons
    ingress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }
    # Recommended outbound traffic for Node groups
    egress_all = {
      description      = "Node all egress"
      protocol         = "-1"
      from_port        = 0
      to_port          = 0
      type             = "egress"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }

    # Allows Control Plane Nodes to talk to Worker nodes on all ports. Added this to avoid issues with Add-ons communication with Control plane.
    # This can be restricted further to specific port based on the requirement for each Add-on e.g., metrics-server 4443, spark-operator 8080, karpenter 8443 etc.
    # Change this according to your security requirements if needed

    ingress_cluster_to_node_all_traffic = {
      description                   = "Cluster API to Nodegroup all traffic"
      protocol                      = "-1"
      from_port                     = 0
      to_port                       = 0
      type                          = "ingress"
      source_cluster_security_group = true
    }
  }
}

#############################################
#     Custom IAM roles for Node Groups      #
#############################################
data "aws_iam_policy_document" "gold-template_nodegroup_assume_role_policy" {
  statement {
    sid = "EKSWorkerAssumeRole"

    actions = [
      "sts:AssumeRole",
    ]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "gold-template_nodegroup" {
  name                  = "gold-template-node-role-CICD"
  description           = "EKS Managed Node group IAM Role"
  assume_role_policy    = data.aws_iam_policy_document.gold-template_nodegroup_assume_role_policy.json
  path                  = "/"
  force_detach_policies = true
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:aws:iam::aws:policy/CloudWatchFullAccess"
  ]

  tags = var.tags
}

resource "aws_iam_instance_profile" "managed_ng" {
  name = "gold-template-CICD-node-instance-profile"
  role = aws_iam_role.gold-template_nodegroup.name
  path = "/"

  lifecycle {
    create_before_destroy = true
  }

  tags = var.tags
}

#############################################
#             Kubernetes Add-ons            #
#############################################
module "eks_kubernetes_addons" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "~> 1.0" #ensure to update this to the latest/desired version

  cluster_name      = module.eks.eks_cluster_id
  cluster_endpoint  = module.eks.eks_cluster_endpoint
  cluster_version   = module.eks.eks_cluster_version
  oidc_provider_arn = module.eks.eks_oidc_provider_arn

  # EKS Addons 
  eks_addons = {
    aws-ebs-csi-driver = {
      most_recent              = true
      service_account_role_arn = module.ebs_csi_driver_irsa.iam_role_arn
    }
    coredns = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
  }

  enable_metrics_server               = true
  enable_aws_load_balancer_controller = true

  aws_load_balancer_controller = {
    name                 = "aws-load-balancer-controller"
    chart                = "aws-load-balancer-controller"
    repository           = "https://aws.github.io/eks-charts"
    chart_version        = "1.5.5"
    namespace            = "platform"
    timeout              = "1200"
    create_namespace     = true
    role_name            = "gold-template-cluster-CICD-aws-load-balancer-controller-sa-irsa"
    role_name_use_prefix = false
    values = [templatefile("${path.module}/bootstrap/aws-alb-controller.tftpl", {
      ACCOUNT_ID = var.account_id
    })]
  }
}


