variable "docker_tag" {
  description = "docker image tag"
  type        = string
  default     = "latest"
}
variable "cluster_name" {
  description = "Cluster name"
  type        = string
  default     = "jed_rearc_quest"
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
  name = var.cluster_name
}
data "aws_eks_cluster_auth" "cluster" {
  name = var.cluster_name
}

data "aws_acm_certificate" "cert" {
  domain = "esserlabs.com"
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
  chart      = "${path.module}/chart"

  values = [
    file("${path.module}/values/aws.yaml"),
  ]

  set {
    name  = "deployments.rearc-quest.containers.rearc-quest.image"
    value = "johndodson85/rearc-quest:${var.docker_tag}"
  }

  set {
    name = "services.rearc-quest.annotations.service.beta.kubernetes.io/aws-load-balancer-ssl-cert"
    value = "${data.aws_acm_certificate.cert.arn}"
  }

  set {
    name = "services.rearc-quest.annotations.service.beta.kubernetes.io/aws-load-balancer-ssl-ports"
    value = "443"
  }
}
