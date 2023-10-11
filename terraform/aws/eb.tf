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

resource "aws_s3_bucket_versioning" "jed_rearc_quest" {
  bucket = aws_s3_bucket.jed_rearc_quest.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_object" "docker_compose" {
  bucket = aws_s3_bucket.jed_rearc_quest.id
  key    = "${var.last_run_commit}.yaml"
  content = <<EOF
version: '3.8'
services:
  rearc-quest:
    image: "johndodson85/rearc-quest:${var.last_run_commit}"
    ports:
      - "80:3000"
EOF
}

resource "aws_elastic_beanstalk_application" "jed_rearc_quest" {
  name        = "${var.elastic_name}"
  description = "${var.elastic_name}"
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

  setting { 
    namespace = "aws:elbv2:listener:default"
    name      = "ListenerEnabled"
    value     = false
    }
    
  setting {
      namespace = "aws:elbv2:listener:443"
      name      = "ListenerEnabled"
      value     = true
  }

  setting {
      namespace = "aws:elbv2:listener:443"
      name      = "Protocol"
      value     = "HTTPS"
   }

  setting {
    namespace = "aws:elbv2:listener:443"
    name = "SSLCertificateArns"
    value = aws_acm_certificate.cert.arn
  }
  setting {
      namespace = "aws:elbv2:listener:443"
      name      = "SSLPolicy"
      value     = "ELBSecurityPolicy-2016-08"
  }
}

resource "aws_elastic_beanstalk_application_version" "jed_rearc_quest" {
  name        = "${var.elastic_name}-${var.last_run_commit}"
  application = aws_elastic_beanstalk_application.jed_rearc_quest.name
  description = "application version created by terraform"
  bucket      = aws_s3_bucket.jed_rearc_quest.id
  key         = aws_s3_object.docker_compose.id
}
