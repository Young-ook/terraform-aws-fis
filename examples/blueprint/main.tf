terraform {
  required_version = "~> 1.0"
}

provider "aws" {
  region = var.aws_region
}

# vpc
module "vpc" {
  source  = "Young-ook/vpc/aws"
  version = "1.0.3"
  name    = var.name
  tags    = var.tags
  vpc_config = {
    cidr        = var.cidr
    azs         = var.azs
    single_ngw  = true
    subnet_type = "private"
  }
}

### application/kubernetes
module "eks" {
  source             = "Young-ook/eks/aws"
  version            = "1.7.11"
  name               = var.name
  tags               = var.tags
  subnets            = values(module.vpc.subnets["private"])
  kubernetes_version = "1.21"
  enable_ssm         = true
  managed_node_groups = [
    {
      name          = "apps"
      instance_type = "m5.large"
    },
  ]
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
  version      = "1.7.11"
  cluster_name = module.eks.cluster.name
  features     = { enable_metrics = true }
  oidc         = module.eks.oidc
}

module "cluster-autoscaler" {
  source  = "Young-ook/eks/aws//modules/cluster-autoscaler"
  version = "1.7.11"
  oidc    = module.eks.oidc
}

module "metrics-server" {
  source  = "Young-ook/eks/aws//modules/metrics-server"
  version = "1.7.11"
  oidc    = module.eks.oidc
}

module "lb-controller" {
  source  = "Young-ook/eks/aws//modules/lb-controller"
  version = "1.7.11"
  oidc    = module.eks.oidc
  tags    = var.tags
  helm = {
    vars = module.eks.features.fargate_enabled ? {
      vpcId       = module.vpc.vpc.id
      clusterName = module.eks.cluster.name
      } : {
      clusterName = module.eks.cluster.name
    }
  }
}

### cache/redis
locals {
  redis_port = 6379
}

resource "aws_security_group" "redis" {
  name   = join("-", [var.name, "redis"])
  tags   = merge(local.default-tags, var.tags)
  vpc_id = module.vpc.vpc.id

  ingress {
    from_port   = local.redis_port
    to_port     = local.redis_port
    protocol    = "tcp"
    cidr_blocks = [module.vpc.vpc.cidr_block]
  }
}

resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "%*()_=+[]{}<>?"
}

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
  replicas_per_node_group    = 2
  automatic_failover_enabled = true
  multi_az_enabled           = true
  transit_encryption_enabled = true
  auth_token                 = random_password.password.result
  log_delivery_configuration {
    destination      = module.logs["redis"].log_group.name
    destination_type = "cloudwatch-logs"
    log_format       = "text"
    log_type         = "slow-log"
  }
}


### database/aurora
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
    version           = "5.7.mysql_aurora.2.07.1"
    port              = "3306"
    user              = "myuser"
    password          = "supersecret"
    database          = "mydb"
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

resource "time_sleep" "wait" {
  depends_on      = [module.vpc, module.mysql]
  create_duration = "60s"
}

module "proxy" {
  depends_on = [time_sleep.wait]
  source     = "Young-ook/aurora/aws//modules/proxy"
  version    = "2.1.3"
  tags       = var.tags
  subnets    = values(module.vpc.subnets["private"])
  proxy_config = {
    cluster_id = module.mysql.cluster.id
  }
  auth_config = {
    user_name     = module.mysql.user.name
    user_password = module.mysql.user.password
  }
}

/*
### application/loadgen
module "loadgen" {
  depends_on = [module.eks, module.mysql]
  source     = "Young-ook/fis/aws//modules/bzt"
  version    = "1.0.3"
  name       = var.name
  tags       = merge(local.default-tags, var.tags)
  subnets    = values(module.vpc.subnets["private"])
  config     = templatefile("${path.module}/test.yaml", { target = format("http://%s", module.api["a"].load_balancer) })
  task       = templatefile("${path.module}/test.py", {})
}
*/
