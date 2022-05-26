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

locals {
  redis_port = 6379
}

# security/firewall
resource "aws_security_group" "redis" {
  name   = join("-", [var.name, "redis"])
  tags   = merge(local.default-tags, var.tags)
  vpc_id = module.vpc.vpc.id

  ingress {
    from_port   = local.redis_port
    to_port     = local.redis_port
    protocol    = "tcp"
    cidr_blocks = [var.cidr]
  }
}

# application/redis
resource "aws_elasticache_replication_group" "redis" {
  replication_group_id       = var.name
  description                = "Cluster mode enabled ElastiCache for Redis"
  engine                     = "redis"
  engine_version             = "6.x"
  port                       = local.redis_port
  security_group_ids         = [aws_security_group.redis.id]
  node_type                  = "cache.t2.micro"
  parameter_group_name       = "default.redis6.x.cluster.on"
  num_node_groups            = 3
  replicas_per_node_group    = 1
  automatic_failover_enabled = true
  multi_az_enabled           = true

  log_delivery_configuration {
    destination      = module.logs["redis"].log_group.name
    destination_type = "cloudwatch-logs"
    log_format       = "text"
    log_type         = "slow-log"
  }

  ###
  ###

  # parameter = {
  #   "cluster-require-full-coverage" = "no"
  # }
}

# application/ec2
module "ec2" {
  source  = "Young-ook/ssm/aws"
  version = "1.0.0"
  name    = var.name
  tags    = var.tags
  node_groups = [
    {
      name          = "baseline"
      desired_size  = 1
      min_size      = 1
      max_size      = 3
      instance_type = "t3.small"
      tags          = { role = "client" }
      policy_arns   = ["arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy", ]
    },
  ]

  ### Initially, this module places all ec2 instances in a specific Availability Zone (AZ).
  ### This configuration is not fault tolerant when Single AZ goes down.
  ###
  ### After first experiment run, switch the 'subnets' variable to the list of whole private subnets created in the example.

  subnets = [module.vpc.subnets[var.use_default_vpc ? "public" : "private"][var.azs[random_integer.az.result]]]
  # subnets = values(module.vpc.subnets[var.use_default_vpc ? "public" : "private"])
}
