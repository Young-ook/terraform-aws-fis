terraform {
  required_version = "~> 1.0"
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

### vpc
module "vpc" {
  source  = "Young-ook/vpc/aws"
  version = "1.0.5"
  name    = join("-", [var.name, "vpc"])
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
  version            = "2.0.0"
  name               = join("-", [var.name, "kubernetes"])
  tags               = var.tags
  subnets            = values(module.vpc.subnets["private"])
  kubernetes_version = var.kubernetes_version
  enable_ssm         = true
  managed_node_groups = [
    {
      name          = "apps"
      desired_size  = 3
      instance_type = "m5.large"
    },
    {
      name          = "spot"
      desired_size  = 3
      capacity_type = "SPOT"
      instance_type = "m5.large"
      tags          = { "chaos" = "ready" }
    },
  ]
}

provider "helm" {
  kubernetes {
    host                   = module.eks.kubeauth.host
    token                  = module.eks.kubeauth.token
    cluster_ca_certificate = module.eks.kubeauth.ca
  }
}

### helm-addons
module "helm-addons" {
  depends_on = [module.eks]
  source     = "Young-ook/eks/aws//modules/helm-addons"
  version    = "2.0.6"
  tags       = var.tags
  addons = [
    {
      ### You can disable the mutator webhook feature by setting the helm chart value enableServiceMutatorWebhook to false.
      ### https://github.com/kubernetes-sigs/aws-load-balancer-controller/releases/tag/v2.5.1
      repository     = "https://aws.github.io/eks-charts"
      name           = "aws-load-balancer-controller"
      chart_name     = "aws-load-balancer-controller"
      chart_version  = "1.5.2"
      namespace      = "kube-system"
      serviceaccount = "aws-load-balancer-controller"
      values = {
        "clusterName"                 = module.eks.cluster.name
        "enableServiceMutatorWebhook" = "false"
      }
      oidc        = module.eks.oidc
      policy_arns = [aws_iam_policy.lbc.arn]
    },
    {
      repository     = "https://aws.github.io/eks-charts"
      name           = "aws-cloudwatch-metrics"
      chart_name     = "aws-cloudwatch-metrics"
      namespace      = "kube-system"
      serviceaccount = "aws-cloudwatch-metrics"
      values = {
        "clusterName" = module.eks.cluster.name
      }
      oidc        = module.eks.oidc
      policy_arns = ["arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"]
    },
    {
      repository     = "https://aws.github.io/eks-charts"
      name           = "aws-for-fluent-bit"
      chart_name     = "aws-for-fluent-bit"
      namespace      = "kube-system"
      serviceaccount = "aws-for-fluent-bit"
      values = {
        "cloudWatch.enabled"      = true
        "cloudWatch.region"       = var.aws_region
        "cloudWatch.logGroupName" = format("/aws/containerinsights/%s/application", module.eks.cluster.name)
        "firehose.enabled"        = false
        "kinesis.enabled"         = false
        "elasticsearch.enabled"   = false
      }
      oidc        = module.eks.oidc
      policy_arns = ["arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"]
    },
    {
      repository     = "${path.module}/charts/"
      name           = "cluster-autoscaler"
      chart_name     = "cluster-autoscaler"
      namespace      = "kube-system"
      serviceaccount = "cluster-autoscaler"
      values = {
        "awsRegion"                 = var.aws_region
        "autoDiscovery.clusterName" = module.eks.cluster.name
      }
      oidc        = module.eks.oidc
      policy_arns = [aws_iam_policy.cas.arn]
    },
    {
      repository     = "${path.module}/charts/"
      name           = "aws-fis-controller"
      chart_name     = "aws-fis-controller"
      namespace      = "kube-system"
      serviceaccount = "aws-fis-controller"
    },
    {
      repository     = "https://kubernetes-sigs.github.io/metrics-server/"
      name           = "metrics-server"
      chart_name     = "metrics-server"
      namespace      = "kube-system"
      serviceaccount = "metrics-server"
      values = {
        "args[0]" = "--kubelet-preferred-address-types=InternalIP"
      }
    },
    {
      repository     = "https://charts.chaos-mesh.org"
      name           = "chaos-mesh"
      chart_name     = "chaos-mesh"
      namespace      = "chaos-mesh"
      serviceaccount = "chaos-mesh-controller"
    },
  ]
}

### security/policy
resource "aws_iam_policy" "cas" {
  name        = "cluster-autoscaler"
  tags        = merge({ "terraform.io" = "managed" }, var.tags)
  description = format("Allow cluster-autoscaler to manage AWS resources")
  policy      = file("${path.module}/policy.cluster-autoscaler.json")
}

resource "aws_iam_policy" "lbc" {
  name        = "aws-loadbalancer-controller"
  tags        = merge({ "terraform.io" = "managed" }, var.tags)
  description = format("Allow aws-load-balancer-controller to manage AWS resources")
  policy      = file("${path.module}/policy.aws-loadbalancer-controller.json")
}

provider "kubernetes" {
  alias                  = "aws-auth"
  host                   = module.eks.kubeauth.host
  token                  = module.eks.kubeauth.token
  cluster_ca_certificate = module.eks.kubeauth.ca
}

### cache/redis
resource "aws_security_group" "redis" {
  depends_on = [module.vpc]
  name       = join("-", [var.name, "redis"])
  tags       = merge(var.tags, local.default-tags)
  vpc_id     = module.vpc.vpc.id

  ingress {
    from_port   = "6379"
    to_port     = "6379"
    protocol    = "tcp"
    cidr_blocks = [module.vpc.vpc.cidr_block]
  }
}

resource "random_password" "redis" {
  length           = 16
  special          = true
  override_special = "!&#$^<>-"
}

resource "aws_elasticache_subnet_group" "redis" {
  depends_on = [module.vpc]
  name       = join("-", [var.name, "redis"])
  subnet_ids = values(module.vpc.subnets["private"])
}

resource "aws_elasticache_replication_group" "redis" {
  depends_on                 = [module.vpc]
  replication_group_id       = join("-", [var.name, "redis"])
  description                = "Cluster mode enabled ElastiCache for Redis"
  tags                       = merge(var.tags, local.default-tags)
  engine                     = "redis"
  engine_version             = "6.x"
  port                       = "6379"
  node_type                  = "cache.t2.micro"
  security_group_ids         = [aws_security_group.redis.id]
  subnet_group_name          = aws_elasticache_subnet_group.redis.name
  parameter_group_name       = "default.redis6.x.cluster.on"
  num_node_groups            = 3
  replicas_per_node_group    = 2
  automatic_failover_enabled = true
  multi_az_enabled           = true
  transit_encryption_enabled = true
  auth_token                 = random_password.redis.result
  log_delivery_configuration {
    destination      = module.logs["redis"].log_group.name
    destination_type = "cloudwatch-logs"
    log_format       = "text"
    log_type         = "slow-log"
  }
}

### database/aurora
module "rds" {
  depends_on = [module.vpc]
  source     = "Young-ook/aurora/aws"
  version    = "2.2.1"
  name       = join("-", [var.name, "rds"])
  tags       = merge(var.tags, local.default-tags)
  vpc        = module.vpc.vpc.id
  subnets    = values(module.vpc.subnets["private"])
  cidrs      = [var.cidr]
  cluster = {
    engine            = "aurora-mysql"
    family            = "aurora-mysql8.0"
    version           = "8.0.mysql_aurora.3.01.0"
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
  instances = [
    {
      instance_type = "db.t3.medium"
    },
    {
      instance_type = "db.t3.medium"
    }
  ]
}

resource "time_sleep" "wait" {
  depends_on      = [module.vpc, module.rds]
  create_duration = "60s"
}

module "proxy" {
  depends_on = [time_sleep.wait]
  for_each   = toset(local.rdsproxy_enabled ? ["enabled"] : [])
  source     = "Young-ook/aurora/aws//modules/proxy"
  version    = "2.1.3"
  tags       = merge(var.tags, local.default-tags)
  subnets    = values(module.vpc.subnets["private"])
  proxy_config = {
    cluster_id = module.rds.cluster.id
  }
  auth_config = {
    user_name     = module.rds.user.name
    user_password = module.rds.user.password
  }
}

### network/dns
resource "aws_route53_zone" "dns" {
  name = local.namespace
  tags = merge(var.tags, local.default-tags)
  vpc {
    vpc_id = module.vpc.vpc.id
  }
}

### application/ec2
module "ec2" {
  for_each   = toset(["a", "b"])
  depends_on = [module.random-az]
  source     = "./modules/api"
  name       = join("-", [var.name, "ec2", each.key])
  tags       = merge(var.tags, local.default-tags)
  dns        = aws_route53_zone.dns.zone_id
  vpc        = module.vpc.vpc.id
  cidr       = module.vpc.vpc.cidr_block
  subnets    = values(module.vpc.subnets["public"])

  ### Initially, this module places all ec2 instances in a specific Availability Zone (AZ).
  ### This configuration is not fault tolerant when Single AZ goes down.
  ### After our first attempt at experimenting with 'terminte ec2 instances'
  ### We will scale the autoscaling-group cross-AZ for high availability.
  ###
  ### Change the 'single_az' variable to 'false' in the toggle.tf file to switch to the multi-az deployment.

  az = local.single_az ? module.random-az.index : -1
}

### network/mesh
module "mesh" {
  depends_on = [module.ec2]
  source     = "./modules/mesh"
  name       = join("-", [var.name, "ec2"])
  tags       = merge(var.tags, local.default-tags)
  aws_region = var.aws_region
  app        = module.ec2
  namespace  = local.namespace
}
