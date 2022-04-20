name               = "fis-rds"
tags               = {}
aws_region         = "ap-northeast-2"
azs                = ["ap-northeast-2a", "ap-northeast-2b", "ap-northeast-2c"]
cidr               = "10.2.0.0/16"
use_default_vpc    = false
kubernetes_version = "1.21"
aurora_cluster = {
  engine            = "aurora-mysql"
  version           = "5.7.12"
  port              = "3306"
  user              = "yourid"
  database          = "yourdb"
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
    instance_parameters = {
      autocommit = 0
    }
  },
  {
    instance_type = "db.t3.medium"
  }
]
