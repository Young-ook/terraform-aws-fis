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
    single_ngw  = true
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
  kubernetes_version = "1.21"
  enable_ssm         = true
  managed_node_groups = [
    {
      name          = "lamp"
      instance_type = "t3.medium"
    },
  ]
}

# aurora
module "mysql" {
  source  = "Young-ook/aurora/aws"
  version = "2.1.2"
  name    = var.name
  tags    = var.tags
  vpc     = module.vpc.vpc.id
  subnets = values(module.vpc.subnets["private"])
  cidrs   = [var.cidr]
  aurora_cluster = {
    engine            = "aurora-mysql"
    version           = "5.7.12"
    port              = "3306"
    user              = "normaluser"
    password          = "supersecret"
    database          = "myDB"
    backup_retention  = "5"
    apply_immediately = "false"
    cluster_parameters = {
      character_set_server = "utf8"
      character_set_client = "utf8"
    }
  }
  aurora_instances = [
    {
      instance_type = "db.t3.medium"
    },
    {
      instance_type = "db.t3.medium"
    }
  ]
}
