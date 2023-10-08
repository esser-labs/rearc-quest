variable "chart_root" {
  description = "Helm chart root dir"
  type        = string
  default     = "../helm"
}

data "terraform_remote_state" "eks" {
  backend = "remote"
  config = {
    organization = "EsserLabs"
    workspaces = {
      name = "rearc-quest"
    }
  }
}

data "aws_eks_cluster" "cluster" {
  name = data.terraform_remote_state.eks.outputs.cluster_name
}
data "aws_eks_cluster_auth" "cluster" {
  name = data.terraform_remote_state.eks.outputs.cluster_name
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", data.aws_eks_cluster.cluster.name]
      command     = "aws"
    }
  }
}

resource "helm_release" "rearc_quest" {
  name       = "rearc-quest"
  chart      = "${var.chart_root}/chart"

  values = [
    file("${var.chart_root}/values/aws.yaml")
  ]
}
