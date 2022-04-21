# application/build
module "ci" {
  source      = "Young-ook/spinnaker/aws//modules/codebuild"
  version     = "2.3.1"
  name        = var.name
  tags        = var.tags
  policy_arns = []
  project = {
    source = {
      type      = "GITHUB"
      location  = "https://github.com/Young-ook/terraform-aws-fis.git"
      buildspec = "examples/rds/lampapp/buildspec.yml"
      version   = "main"
    }
    environment = {
      environment_variables = {
        APP_SRC = join("/", ["examples/rds/lampapp"])
        ECR_URI = module.ecr.url
        TAG     = "latest"
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
