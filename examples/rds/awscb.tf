# security/firewall
resource "aws_security_group" "ci" {
  name   = join("-", [var.name, "codebuild"])
  vpc_id = module.vpc.vpc.id
  tags   = var.tags

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# application/build
module "ci" {
  source  = "Young-ook/spinnaker/aws//modules/codebuild"
  version = "2.3.1"
  name    = var.name
  tags    = var.tags
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
      group_name = module.cilogs.log_group.name
    }
  }
  vpc = {
    vpc             = module.vpc.vpc.id
    subnets         = values(module.vpc.subnets["private"])
    security_groups = [aws_security_group.ci.id]
  }
  policy_arns = []
}

module "cilogs" {
  source  = "Young-ook/lambda/aws//modules/logs"
  version = "0.2.1"
  name    = var.name
  log_group = {
    namespace      = "/aws/codebuild"
    retension_days = 5
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
