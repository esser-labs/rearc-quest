variable "last_run_commit" {
  description = "Last run git commit"
  type        = string
  default     = "HEAD"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-2"
}

variable "cluster_name" {
  description = "Cluster name"
  type        = string
  default     = "jed_rearc_quest"
}

provider "aws" {
  region = var.region
}

module "eks" {
  source = "./eks"
  cluster_name = var.cluster_name
  last_run_commit = var.last_run_commit
}

module "helm" {
  source = "./helm"
  cluster_name = var.cluster_name
  docker_tag = var.last_run_commit
}
