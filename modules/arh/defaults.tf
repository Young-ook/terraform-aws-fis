### default variables

### aws partitions
module "aws" {
  source = "Young-ook/spinnaker/aws//modules/aws-partitions"
}

locals {
  aws = {
    dns       = module.aws.partition.dns_suffix
    partition = module.aws.partition.partition
    region    = module.aws.region.name
  }
}

locals {
  default_app = {
    name      = "appcommon"
    type      = "AWS::ResilienceHub::AppCommonAppComponent"
    resources = []
  }
  default_policy = {
    tier = "MissionCritical"
    rto  = 600
    rpo  = 600
  }
}
