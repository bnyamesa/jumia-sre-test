variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for the EKS cluster"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the EKS cluster"
  type        = list(string)
}

variable "desired_capacity" {
  description = "Desired capacity for the EKS node group"
  type        = number
}

variable "min_capacity" {
  description = "Minimum capacity for the EKS node group"
  type        = number
}

variable "max_capacity" {
  description = "Maximum capacity for the EKS node group"
  type        = number
}

variable "project_name" {
  description = "Project name for tagging"
  type        = string
}

module "eks_cluster" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "18.0.3"  # Ensure this version is used
  cluster_name    = var.cluster_name
  cluster_version = "1.21"
  vpc_id          = var.vpc_id
  subnet_ids      = var.subnet_ids

  managed_node_groups = {
    eks_managed = {
      desired_capacity = var.desired_capacity
      min_size         = var.min_capacity
      max_size         = var.max_capacity
      instance_type    = "t3.micro"
    }
  }

  tags = {
    Project = var.project_name
  }
}

output "eks_cluster_endpoint" {
  value = module.eks_cluster.cluster_endpoint
}

output "eks_cluster_name" {
  value = module.eks_cluster.cluster_name
}
