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
    subnet_type = "private"
    single_ngw  = true
  }
}

# application/redis
module "redis" {
  source                               = "cloudposse/elasticache-redis/aws"
  version                              = "0.42.1"
  name                                 = var.name
  vpc_id                               = module.vpc.vpc.id
  subnets                              = values(module.vpc.subnets[var.use_default_vpc ? "public" : "private"])
  availability_zones                   = var.azs
  allowed_security_groups              = [aws_security_group.redis-aware.id]
  apply_immediately                    = true
  automatic_failover_enabled           = true
  multi_az_enabled                     = true
  cluster_mode_enabled                 = true
  cluster_mode_num_node_groups         = 3
  cluster_mode_replicas_per_node_group = 2
  instance_type                        = "cache.t2.micro"
  family                               = "redis6.x"
  engine_version                       = "6.x"

  ###
  ###

  # parameter = {
  #   "cluster-require-full-coverage" = "no"
  # }
}

# security/firewall
resource "aws_security_group" "redis-aware" {
  name   = join("-", [var.name, "redis-aware"])
  tags   = merge(local.default-tags, var.tags)
  vpc_id = module.vpc.vpc.id

  egress {
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = [var.cidr]
  }
}

# application/ec2
module "ec2" {
  source  = "Young-ook/ssm/aws"
  version = "1.0.0"
  name    = var.name
  tags    = var.tags
  node_groups = [
    {
      name            = "baseline"
      desired_size    = 1
      min_size        = 1
      max_size        = 3
      instance_type   = "t3.small"
      tags            = { role = "client" }
      security_groups = [aws_security_group.redis-aware.id]
      policy_arns     = ["arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy", ]
    },
  ]

  ### Initially, this module places all ec2 instances in a specific Availability Zone (AZ).
  ### This configuration is not fault tolerant when Single AZ goes down.
  ###
  ### After first experiment run, switch the 'subnets' variable to the list of whole private subnets created in the example.

  subnets = [module.vpc.subnets[var.use_default_vpc ? "public" : "private"][var.azs[random_integer.az.result]]]
  # subnets = values(module.vpc.subnets[var.use_default_vpc ? "public" : "private"])
}
