### monitoring/agent
resource "aws_ssm_association" "cwagent" {
  association_name = "SSM-StartCWAgent"
  name             = "AmazonCloudWatch-ManageAgent"
  parameters = {
    action = "start"
  }
  targets {
    key    = "tag:release"
    values = ["baseline", "canary"]
  }
}

# application/logs
module "logs" {
  source  = "Young-ook/lambda/aws//modules/logs"
  version = "0.2.1"
  for_each = { for l in [
    {
      type = "fis"
      log_group = {
        namespace      = "/aws/fis"
        retension_days = 3
      }
    },
  ] : l.type => l }
  name      = join("-", [var.name, each.key])
  log_group = each.value.log_group
}
