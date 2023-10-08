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

module "helm" {
  source = "./helm"
}
