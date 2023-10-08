variable "chart_root" {
  description = "Helm chart root dir"
  type        = string
  default     = "../helm"
}
variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-2"
}

provider "aws" {
  region = var.region
}

module "eks" {
  source = "./eks"
}

data "aws_eks_cluster" "cluster" {
  name = module.eks.module.eks.cluster_name
  depends_on = [module.eks]
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.module.eks.cluster_name
  depends_on = [module.eks]
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", data.aws_eks_cluster.cluster.name]
    command     = "aws"
  }
}

module "helm" {
  source = "./helm"
  depends_on = [module.eks]
}
