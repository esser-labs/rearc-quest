provider "aws" {
  region = var.region
}

module "eks" {
  source = "./eks.tf"
}

module "helm" {
  source = "./helm.tf"
}
