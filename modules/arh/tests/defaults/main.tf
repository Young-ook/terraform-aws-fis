terraform {
  required_providers {
    test = {
      source = "terraform.io/builtin/test"
    }
  }
}

module "vpc" {
  source  = "Young-ook/vpc/aws"
  version = "1.0.7"
}

module "eks" {
  source              = "Young-ook/eks/aws"
  version             = "2.0.10"
  subnets             = values(module.vpc.subnets["public"])
  kubernetes_version  = "1.27"
  enable_ssm          = true
  managed_node_groups = [{ name = "default" }, ]
}

### application
### https://docs.aws.amazon.com/resilience-hub/latest/APIReference/API_AddDraftAppVersionResourceMappings.html
### https://docs.aws.amazon.com/resilience-hub/latest/APIReference/API_PutDraftAppVersionTemplate.html
locals {
  state_file_mapping = [
    {
      ### Available values for mapping type:
      ### CfnStack | Resource | AppRegistryApp | ResourceGroup | Terraform | EKS
      mapping_type          = "Terraform"
      terraform_source_name = "TerraformStateFile"
      physical_resource_id = {
        identifier = "s3://tfstate"
        type       = "Native"
      }
    }
  ]
  eks_mapping = [
    {
      mapping_type    = "EKS"
      eks_source_name = format("%s/%s", module.eks.cluster.name, "default")
      physical_resource_id = {
        identifier = format("%s/%s", module.eks.cluster.control_plane.arn, "default")
        type       = "Arn"
      }
    }
  ]
  eks_app_components = {
    appComponents = [{
      name          = module.eks.cluster.name
      type          = "AWS::ResilienceHub::ComputeAppComponent"
      resourceNames = [module.eks.cluster.name]
    }]
    resources = [{
      name = module.eks.cluster.name
      type = "AWS::EKS::Deployment"
      logicalResourceId = {
        identifier    = module.eks.cluster.name
        eksSourceName = format("%s/%s", module.eks.cluster.name, "default")
      }
    }]
    excludedResources = {}
    version           = 2
  }
}

module "main" {
  source = "../.."
  application = {
    components        = local.eks_app_components
    resource_mappings = local.eks_mapping
  }
}
