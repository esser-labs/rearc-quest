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

variable "elastic_name" {
  description = "Cluster name"
  type        = string
  default     = "jed-rearc-quest"
}

data "aws_availability_zones" "available" {
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

# Force a resource update to prevent Github action from failing when applying EKS changes and actual resources have not changed
resource "random_id" "force_run" {
  keepers = {
    first = "${var.last_run_commit}"
  }     
  byte_length = 8
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.0.0"

  name = "${var.cluster_name}-vpc"

  cidr = "10.0.0.0/16"
  azs  = slice(data.aws_availability_zones.available.names, 0, 3)

  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  public_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                      = 1
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"             = 1
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.15.3"

  cluster_name    = var.cluster_name
  cluster_version = "1.27"

  vpc_id                         = module.vpc.vpc_id
  subnet_ids                     = module.vpc.private_subnets
  cluster_endpoint_public_access = true

  eks_managed_node_group_defaults = {
    ami_type = "AL2_x86_64"

  }

  eks_managed_node_groups = {
    one = {
      name = "${var.cluster_name}-1"

      instance_types = ["t3.small"]

      min_size     = 1
      max_size     = 3
      desired_size = 2
    }
  }
}

data "aws_iam_policy" "ebs_csi_policy" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

module "irsa-ebs-csi" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version = "4.7.0"

  create_role                   = true
  role_name                     = "AmazonEKSTFEBSCSIRole-${module.eks.cluster_name}"
  provider_url                  = module.eks.oidc_provider
  role_policy_arns              = [data.aws_iam_policy.ebs_csi_policy.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
}

resource "aws_eks_addon" "ebs-csi" {
  cluster_name             = module.eks.cluster_name
  addon_name               = "aws-ebs-csi-driver"
  addon_version            = "v1.20.0-eksbuild.1"
  service_account_role_arn = module.irsa-ebs-csi.iam_role_arn
  tags = {
    "eks_addon" = "ebs-csi"
    "terraform" = "true"
  }
}

resource "aws_iam_role" "beanstalk_service" {
  name = "elastic_beanstalk_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "beanstalk_log_attach" {
  role       = aws_iam_role.beanstalk_service.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWebTier"
}

resource "aws_iam_instance_profile" "beanstalk_iam_instance_profile" {
  name = "beanstalk_iam_instance_profile"
  role = aws_iam_role.beanstalk_service.name
}

resource "aws_s3_bucket" "jed_rearc_quest" {
  bucket = "${var.elastic_name}"

  tags = {
    Name = "${var.elastic_name}"
  }
}

resource "aws_s3_object" "jed_rearc_quest" {
  bucket = aws_s3_bucket.jed_rearc_quest.id
  key    = "Dockerrun.aws.json"
  content = <<EOF
{
  "AWSEBDockerrunVersion": "1",
  "Image": {
    "Name": "johndodson85/rearc-quest:${var.last_run_commit}",
    "Update": "true"
  },
  "Ports": [
    {
      "ContainerPort": "3000",
      "HostPort": "3000
    }
  ]
}
EOF
}

resource "aws_elastic_beanstalk_application" "jed_rearc_quest" {
  name        = "${var.cluster_name}"
  description = "${var.cluster_name}"
}

resource "aws_elastic_beanstalk_environment" "jed_rearc_quest" {
  name         = "${var.elastic_name}"
  application  = aws_elastic_beanstalk_application.jed_rearc_quest.name
  cname_prefix = "rearc-quest"

  solution_stack_name = "64bit Amazon Linux 2023 v4.0.1 running Docker"

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = aws_iam_instance_profile.beanstalk_iam_instance_profile.arn
  }

  setting {
    namespace = "aws:elasticbeanstalk:cloudwatch:logs"
    name      = "StreamLogs"
    value     = "True"
  }
}

resource "tls_private_key" "jed_rearc_quest" {
  algorithm = "RSA"
}

resource "tls_self_signed_cert" "jed_rearc_quest" {
  private_key_pem = tls_private_key.jed_rearc_quest.private_key_pem

  subject {
    common_name  = "esserlabs.com"
    organization = "Esser Labs"
  }

  validity_period_hours = 168

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

resource "aws_acm_certificate" "cert" {
  private_key      = tls_private_key.jed_rearc_quest.private_key_pem
  certificate_body = tls_self_signed_cert.jed_rearc_quest.cert_pem
}

resource "aws_elastic_beanstalk_application_version" "jed_rearc_quest" {
  name        = "${var.elastic_name}-${var.last_run_commit}"
  application = aws_elastic_beanstalk_application.jed_rearc_quest.name
  description = "application version created by terraform"
  bucket      = aws_s3_bucket.jed_rearc_quest.id
  key         = aws_s3_object.jed_rearc_quest.id
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
}

output "cluster_security_group_id" {
  description = "Security group ids attached to the cluster control plane"
  value       = module.eks.cluster_security_group_id
}

output "region" {
  description = "AWS region"
  value       = var.region
}

output "cluster_name" {
  description = "Kubernetes Cluster Name"
  value       = module.eks.cluster_name
}

output "last_run_commit" {
  description = "Last run git commit"
  value       = var.last_run_commit
}
