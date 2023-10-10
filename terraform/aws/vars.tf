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
