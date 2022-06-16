# application/build
module "ci" {
  source  = "Young-ook/spinnaker/aws//modules/codebuild"
  version = "2.3.1"
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
  content = templatefile(join("/", [path.cwd, "templates", "lamp.tpl"]),
    {
      ecr_url    = module.ecr.url
      mysql_host = module.mysql.endpoint.writer
      mysql_user = module.mysql.user.name
      mysql_pw   = module.mysql.user.password
      mysql_db   = module.mysql.user.database
    }
  )
  filename        = join("/", [path.cwd, "lamp", "lamp.yaml"])
  file_permission = "0600"
}
