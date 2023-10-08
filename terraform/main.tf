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

module "helm" {
  source = "./helm"
}
