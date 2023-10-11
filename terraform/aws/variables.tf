variable "elastic_name" {
  description = "Elastic Beanstalk name"
  type        = string
  default     = "jed-rearc-quest"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-2"
}

variable "last_run_commit" {
  description = "Last run git commit"
  type        = string
  default     = "HEAD"
}

variable "cluster_name" {
  description = "Cluster name"
  type        = string
  default     = "jed_rearc_quest"
}

variable "vpc_cidr_block" {
  description = "VPC CIDR Block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "vpc_public_subnets" {
  description = "VPC Public subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
}

variable "vpc_private_subnets" {
  description = "VPC private subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}
