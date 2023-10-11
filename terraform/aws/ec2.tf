resource "aws_security_group" "allow_ssh_rearc" {
  name        = "allow_ssh_rearc"
  description = "Allow SSH and HTTP Rearc app traffic"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description      = "HTTP from VPC"
    from_port        = 3000
    to_port          = 3000
    protocol         = "tcp"
    cidr_blocks      = [var.vpc_cidr_block]
  }

  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_tls"
  }
}

resource "aws_instance" "jed_rearc_quest" {
  ami           = "ami-004e8b78272c56a7c" // preconfigured ami with docker on it
  instance_type = "t2.micro"
  key_name = "jed_rearc_quest"
  subnet_id = module.vpc.public_subnets[0]
  vpc_security_group_ids = [aws_security_group.allow_ssh_rearc.id]
  associate_public_ip_address = true

  tags = {
    Name = "jed_rearc_quest-${var.last_run_commit}"
  }

  user_data = <<EOF
#!/bin/bash
running=$(docker ps | grep quest)

if [ ! -z "$running" ]; then
  echo "Killing quest container"
  docker kill quest
fi

exists=$(docker ps -a | grep quest)

if [ ! -z "$exists" ]; then
  echo "Removing quest container"
  docker rm quest
fi

echo "Starting quest container"
docker run -d -p 3000:3000 -e SECRET_WORD=TwelveFactor --name quest johndodson85/rearc-quest:${var.last_run_commit}

EOF
}

resource "aws_security_group" "elb_security_group" {
  name        = "allow_ssh_rearc"
  description = "Allow SSH and HTTP Rearc app traffic"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "HTTPS"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_tls"
  }
}

resource "aws_elb" "jed_rearc_quest" {
  name               = "jedrearcquest"
  subnets = module.vpc.public_subnets

  listener {
    instance_port     = 3000
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  listener {
    instance_port      = 3000
    instance_protocol  = "http"
    lb_port            = 443
    lb_protocol        = "https"
    ssl_certificate_id = aws_acm_certificate.cert.arn
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 20
    target              = "HTTP:3000/"
    interval            = 30
  }

  instances                   = [aws_instance.jed_rearc_quest.id]
  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  security_groups = [aws_security_group.elb_security_group.id]

  tags = {
    Name = "jed_rearc_quest"
  }
}
