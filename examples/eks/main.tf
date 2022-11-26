terraform {
  required_version = "~> 1.0"
}

provider "aws" {
  region = var.aws_region
}

# network/vpc
module "vpc" {
  source  = "Young-ook/vpc/aws"
  version = "1.0.2"
  name    = var.name
  tags    = var.tags
  vpc_config = var.use_default_vpc ? null : {
    cidr        = var.cidr
    azs         = var.azs
    subnet_type = "private"
    single_ngw  = true
  }
}

# application/eks
module "eks" {
  source              = "Young-ook/eks/aws"
  version             = "1.7.10"
  name                = var.name
  tags                = var.tags
  subnets             = values(module.vpc.subnets["private"])
  kubernetes_version  = var.kubernetes_version
  enable_ssm          = true
  fargate_profiles    = var.fargate_profiles
  managed_node_groups = var.managed_node_groups
}

provider "helm" {
  kubernetes {
    host                   = module.eks.helmconfig.host
    token                  = module.eks.helmconfig.token
    cluster_ca_certificate = base64decode(module.eks.helmconfig.ca)
  }
}

module "container-insights" {
  source       = "Young-ook/eks/aws//modules/container-insights"
  version      = "1.7.10"
  cluster_name = module.eks.cluster.name
  features     = { enable_metrics = true }
  oidc         = module.eks.oidc
}

module "cluster-autoscaler" {
  source  = "Young-ook/eks/aws//modules/cluster-autoscaler"
  version = "1.7.10"
  oidc    = module.eks.oidc
}

module "metrics-server" {
  source  = "Young-ook/eks/aws//modules/metrics-server"
  version = "1.7.10"
  oidc    = module.eks.oidc
}

module "chaos-mesh" {
  source  = "Young-ook/eks/aws//modules/chaos-mesh"
  version = "1.7.7"
  oidc    = module.eks.oidc
}

module "app-mesh" {
  source  = "Young-ook/eks/aws//modules/app-mesh"
  version = "1.7.10"
  oidc    = module.eks.oidc
  helm = {
    version = "1.2.0"
  }
}

module "lb-controller" {
  source  = "Young-ook/eks/aws//modules/lb-controller"
  version = "1.7.10"
  oidc         = module.eks.oidc
  tags         = var.tags
  helm = {
    vars = module.eks.features.fargate_enabled ? {
      vpcId       = module.vpc.vpc.id
      clusterName = module.eks.cluster.name
      } : {
      clusterName = module.eks.cluster.name
    }
  }
}
