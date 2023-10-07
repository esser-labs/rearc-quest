terraform {

  cloud {
    workspaces {
      name = "jed-rearc-quest"
    }
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.7.0"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.8.0"
    }
    
    cloudinit = {
      source  = "hashicorp/cloudinit"
      version = "~> 2.3.2"
    }
    
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0.4"
    }
  }

  required_version = "~> 1.6"
}
