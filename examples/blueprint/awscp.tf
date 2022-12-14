### application/build
locals {
  projects = [
    {
      name      = "lamp"
      repo      = "lamp"
      buildspec = "examples/blueprint/apps/lamp/buildspec.yml"
      app_path  = "examples/blueprint/apps/lamp"
    },
    {
      name      = "redispy"
      repo      = "redispy"
      buildspec = "examples/blueprint/apps/redispy/buildspec.yml"
      app_path  = "examples/blueprint/apps/redispy"
    },
  ]
}

module "ci" {
  for_each = { for proj in local.projects : proj.name => proj }
  source   = "Young-ook/spinnaker/aws//modules/codebuild"
  version  = "2.3.6"
  name     = each.key
  tags     = var.tags
  project = {
    source = {
      type      = "GITHUB"
      location  = "https://github.com/Young-ook/terraform-aws-fis.git"
      buildspec = lookup(each.value, "buildspec")
      version   = "main"
    }
    environment = {
      compute_type    = lookup(each.value, "compute_type", "BUILD_GENERAL1_SMALL")
      type            = lookup(each.value, "type", "LINUX_CONTAINER")
      image           = lookup(each.value, "image", "aws/codebuild/standard:4.0")
      privileged_mode = true
      environment_variables = {
        APP_SRC = lookup(each.value, "app_path")
        ECR_URI = module.ecr[lookup(each.value, "repo")].url
      }
    }
  }
  policy_arns = [
    module.ecr[lookup(each.value, "repo")].policy_arns["read"],
    module.ecr[lookup(each.value, "repo")].policy_arns["write"],
  ]
  log = {
    cloudwatch_logs = {
      group_name = module.logs["codebuild"].log_group.name
    }
  }
}

module "ecr" {
  for_each     = { for proj in local.projects : proj.repo => proj... }
  source       = "Young-ook/eks/aws//modules/ecr"
  version      = "1.7.11"
  name         = each.key
  scan_on_push = false
}

# application/manifest
resource "local_file" "lamp" {
  depends_on = [module.ecr]
  content = templatefile(join("/", [path.module, "apps", "lamp", "lamp.yaml.tpl"]),
    {
      ecr_url    = module.ecr["lamp"].url
      mysql_host = module.rds.endpoint.writer
      mysql_user = module.rds.user.name
      mysql_pw   = module.rds.user.password
      mysql_db   = module.rds.user.database
    }
  )
  filename        = join("/", [path.module, "apps", "lamp", "lamp.yaml"])
  file_permission = "0400"
}

resource "local_file" "redispy" {
  depends_on = [module.ecr]
  content = templatefile(join("/", [path.module, "apps", "redispy", "redispy.yaml.tpl"]),
    {
      ecr_url        = module.ecr["redispy"].url
      redis_endpoint = aws_elasticache_replication_group.redis.configuration_endpoint_address
      redis_password = random_password.password.result
    }
  )
  filename        = join("/", [path.module, "apps", "redispy", "redispy.yaml"])
  file_permission = "0400"
}
