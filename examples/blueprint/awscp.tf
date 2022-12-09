# application/build
module "ci" {
  source  = "Young-ook/spinnaker/aws//modules/codebuild"
  version = "2.3.2"
  name    = var.name
  tags    = var.tags
  policy_arns = [
    module.ecr.policy_arns["write"],
    module.ecr.policy_arns["read"]
  ]
  project = {
    source = {
      type      = "GITHUB"
      location  = "https://github.com/Young-ook/terraform-aws-fis.git"
      buildspec = "examples/rds/lamp/buildspec.yml"
      version   = "main"
    }
    environment = {
      image           = "aws/codebuild/standard:4.0"
      privileged_mode = true
      environment_variables = {
        APP_SRC = join("/", ["examples/rds/lamp"])
        ECR_URI = module.ecr.url
      }
    }
  }
  log = {
    cloudwatch_logs = {
      group_name = module.logs["codebuild"].log_group.name
    }
  }
}

# application/repo
module "ecr" {
  source       = "Young-ook/eks/aws//modules/ecr"
  version      = "1.7.5"
  namespace    = var.name
  name         = "lamp"
  scan_on_push = false
}

# application/manifest
resource "local_file" "lamp" {
  depends_on = [module.ecr]
  content = templatefile(join("/", [path.module, "apps", "lamp", "lamp.yaml.tpl"]),
    {
      ecr_url    = module.ecr.url
      mysql_host = module.mysql.endpoint.writer
      mysql_user = module.mysql.user.name
      mysql_pw   = module.mysql.user.password
      mysql_db   = module.mysql.user.database
    }
  )
  filename        = join("/", [path.module, "apps", "lamp", "lamp.yaml"])
  file_permission = "0400"
}

resource "local_file" "redispy" {
  depends_on = [module.ecr]
  content = templatefile(join("/", [path.module, "apps", "redispy", "redispy.yaml.tpl"]),
    {
      ecr_url        = module.ecr.url
      redis_endpoint = aws_elasticache_replication_group.redis.configuration_endpoint_address
      redis_password = random_password.password.result
    }
  )
  filename        = join("/", [path.module, "apps", "redispy", "redispy.yaml"])
  file_permission = "0400"
}
