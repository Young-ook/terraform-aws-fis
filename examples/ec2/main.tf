terraform {
  required_version = "~> 1.0"
  required_providers {
    aws = "> 2.3"
  }
}

provider "aws" {
  region = var.aws_region
}

### network/vpc
module "vpc" {
  source  = "Young-ook/vpc/aws"
  version = "1.0.2"
  name    = var.name
  tags    = var.tags
  vpc_config = var.use_default_vpc ? null : {
    cidr        = var.cidr
    azs         = var.azs
    subnet_type = "public"
    single_ngw  = true
  }
}

### network/dns
resource "aws_route53_zone" "dns" {
  name = local.namespace
  tags = merge(local.default-tags, var.tags)
  vpc {
    vpc_id = module.vpc.vpc.id
  }
}

### network/mesh
module "mesh" {
  depends_on = [module.api, module.loadgen]
  source     = "./modules/mesh"
  name       = var.name
  tags       = merge(local.default-tags, var.tags)
  aws_region = var.aws_region
  app        = module.api
  namespace  = local.namespace
}

### application/api
module "api" {
  for_each   = toset(["a", "b"])
  depends_on = [module.random-az]
  source     = "./modules/api"
  name       = join("-", [var.name, each.key])
  tags       = merge(local.default-tags, var.tags)
  dns        = aws_route53_zone.dns.zone_id
  vpc        = module.vpc.vpc.id
  cidr       = module.vpc.vpc.cidr_block
  subnets    = values(module.vpc.subnets["public"])

  ### Initially, this module places all ec2 instances in a specific Availability Zone (AZ).
  ### This configuration is not fault tolerant when Single AZ goes down.
  ### After our first attempt at experimenting with 'terminte ec2 instances'
  ### We will scale the autoscaling-group cross-AZ for high availability.
  ###
  ### Block the 'az' variable to switch to the multi-az deployment.

  az = module.random-az.index
}

### application/loadgen
module "loadgen" {
  depends_on      = [module.api]
  source          = "Young-ook/fis/aws//modules/bzt"
  version         = "1.0.3"
  name            = var.name
  tags            = merge(local.default-tags, var.tags)
  subnets         = values(module.vpc.subnets["public"])
  security_groups = [module.api["a"].security_group.id, module.api["b"].security_group.id]
  config          = templatefile("${path.module}/test.yaml", { target = format("http://%s", module.api["a"].load_balancer) })
  task            = templatefile("${path.module}/test.py", {})
}
