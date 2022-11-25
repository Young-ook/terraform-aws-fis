name               = "fis-eks"
tags               = {}
aws_region         = "ap-northeast-2"
azs                = ["ap-northeast-2a", "ap-northeast-2b", "ap-northeast-2c"]
cidr               = "10.1.0.0/16"
use_default_vpc    = false
kubernetes_version = "1.21"
fargate_profiles = [
  {
    name      = "locust"
    namespace = "locust"
  },
]
managed_node_groups = [
  {
    name          = "sockshop"
    desired_size  = 1
    min_size      = 1
    max_size      = 4
    instance_type = "m5.large"
  }
]
