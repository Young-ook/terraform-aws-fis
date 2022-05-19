terraform {
  required_version = "~> 1.0"
}

provider "aws" {
  region = var.aws_region
}

# network/vpc
module "vpc" {
  source  = "Young-ook/vpc/aws"
  version = "1.0.1"
  name    = var.name
  tags    = var.tags
  vpc_config = var.use_default_vpc ? null : {
    cidr        = var.cidr
    azs         = var.azs
    subnet_type = "isolated"
    single_ngw  = true
  }
}

# security/firewall
resource "aws_security_group" "alb" {
  name   = join("-", [var.name, "alb"])
  tags   = merge(local.default-tags, var.tags)
  vpc_id = module.vpc.vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "alb_aware" {
  name   = join("-", [var.name, "alb", "aware"])
  tags   = merge(local.default-tags, var.tags)
  vpc_id = module.vpc.vpc.id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = [var.cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# application/loadbalancer
resource "aws_lb" "alb" {
  name                       = join("-", [var.name, "alb"])
  tags                       = merge(local.default-tags, var.tags)
  internal                   = true
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.alb.id]
  subnets                    = values(module.vpc.subnets[var.use_default_vpc ? "public" : "private"])
  enable_deletion_protection = false
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.http.arn
  }
}

resource "aws_lb_target_group" "http" {
  depends_on                    = [aws_lb.alb]
  name                          = join("-", [var.name, "alb", "http"])
  tags                          = merge(local.default-tags, var.tags)
  vpc_id                        = module.vpc.vpc.id
  port                          = 80
  protocol                      = "HTTP"
  target_type                   = "instance"
  load_balancing_algorithm_type = "least_outstanding_requests"
  deregistration_delay          = 10

  health_check {
    enabled  = true
    interval = 30
    path     = "/"
    port     = "traffic-port"
    protocol = "HTTP"
  }
}

# application/script
locals {
  client = join("\n", [
    "#!/bin/bash",
    "while true; do",
    "  curl -I http://${aws_lb.alb.dns_name}",
    "  echo",
    "  sleep 1",
    "done",
    ]
  )
  server = join("\n", [
    "sudo yum update -y",
    "sudo yum install -y httpd",
    "sudo rm /etc/httpd/conf.d/welcome.conf",
    "sudo systemctl start httpd",
    ]
  )
}

# application/ec2
module "ec2" {
  depends_on = [aws_ssm_association.cwagent]
  source     = "Young-ook/ssm/aws"
  version    = "1.0.0"
  name       = var.name
  tags       = var.tags
  node_groups = [
    {
      name              = "baseline"
      min_size          = 3
      max_size          = 6
      desired_size      = 3
      instance_type     = "t3.small"
      security_groups   = [aws_security_group.alb_aware.id]
      target_group_arns = [aws_lb_target_group.http.arn]
      tags              = { release = "baseline" }
      policy_arns       = ["arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"]
      user_data         = local.server
    },
    {
      name              = "canary"
      min_size          = 1
      max_size          = 1
      desired_size      = 1
      instance_type     = "t3.small"
      security_groups   = [aws_security_group.alb_aware.id]
      target_group_arns = [aws_lb_target_group.http.arn]
      tags              = { release = "canary" }
      policy_arns       = ["arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"]
      user_data         = local.server
    },
    {
      name            = "loadgen"
      min_size        = 1
      max_size        = 1
      desired_size    = 1
      instance_type   = "t3.small"
      security_groups = [aws_security_group.alb_aware.id]
      policy_arns     = ["arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"]
      user_data       = local.client
    }
  ]

  ### Initially, this module places all ec2 instances in a specific Availability Zone (AZ).
  ### This configuration is not fault tolerant when Single AZ goes down.
  ### After our first attempt at experimenting with 'terminte ec2 instances'
  ### We will scale the autoscaling-group cross-AZ for high availability.
  ###
  ### Switch the 'subnets' variable to the list of whole private subnets created in the example.

  subnets = [module.vpc.subnets[var.use_default_vpc ? "public" : "private"][var.azs[random_integer.az.result]]]
  # subnets = values(module.vpc.subnets[var.use_default_vpc ? "public" : "private"])
}

resource "aws_autoscaling_policy" "target-tracking" {
  name                   = join("-", [var.name, "target-tracking", "policy"])
  autoscaling_group_name = module.ec2.cluster.data_plane.node_groups.baseline.name
  adjustment_type        = "ChangeInCapacity"

  policy_type = "TargetTrackingScaling"
  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 10.0
  }
}
