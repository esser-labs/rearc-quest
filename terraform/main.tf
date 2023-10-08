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

provider "aws" {
  region = var.region
}

module "eks" {
  source = "./eks"
  last_run_commit = var.last_run_commit
}

module "helm" {
  source = "./helm"
  docker_tag = var.last_run_commit
}
