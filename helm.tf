data "terraform_remote_state" "eks" {
  backend = "remote"
  config = {
    organization = "EsserLabs"
    workspaces = {
      name = "rearc-quest"
    }
  }
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


resource "helm_release" "reacr-quest" {
  name       = "rearc-quest"
  chart      = "./helm/chart"

  values = [
    file("${path.module}/helm/values/aws.yaml")
  ]
}
