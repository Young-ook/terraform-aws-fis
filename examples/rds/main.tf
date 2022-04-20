terraform {
  required_version = "~> 1.0"
}

provider "aws" {
  region = var.aws_region
}

# vpc
module "vpc" {
  source  = "Young-ook/vpc/aws"
  version = "1.0.1"
  name    = var.name
  tags    = var.tags
  vpc_config = {
    cidr        = var.cidr
    azs         = var.azs
    subnet_type = "private"
  }
}

# eks
module "eks" {
  source             = "Young-ook/eks/aws"
  version            = "1.7.5"
  name               = var.name
  tags               = var.tags
  subnets            = values(module.vpc.subnets["private"])
  kubernetes_version = var.kubernetes_version
  enable_ssm         = true
  fargate_profiles = [
    {
      name      = "php-apache"
      namespace = "php-apache"
    },
  ]
}

# aurora
module "mysql" {
  source           = "Young-ook/aurora/aws"
  version          = "2.0.4"
  name             = var.name
  tags             = var.tags
  vpc              = module.vpc.vpc.id
  subnets          = values(module.vpc.subnets["private"])
  cidrs            = [var.cidr]
  aurora_cluster   = var.aurora_cluster
  aurora_instances = var.aurora_instances
}
