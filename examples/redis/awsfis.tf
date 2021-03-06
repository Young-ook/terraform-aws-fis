
### fault injection simulator experiment templates

# drawing lots for choosing a subnet
resource "random_integer" "az" {
  min = 0
  max = length(var.azs) - 1
}

module "awsfis" {
  source  = "Young-ook/fis/aws"
  version = "1.0.1"
  name    = var.name
  tags    = var.tags
  experiments = [
    {
      name     = "az-outage"
      template = "${path.cwd}/templates/az-outage.tpl"
      params = {
        ssm_doc  = module.awsfis.experiment["FIS-Run-AZ-Outage"].arn
        region   = var.aws_region
        az       = var.azs[random_integer.az.result]
        vpc      = module.vpc["vpc"].id
        duration = "PT1M"
        ssm_role = module.awsfis.role["ssm"].arn
        fis_role = module.awsfis.role["fis"].arn
        alarm    = aws_cloudwatch_metric_alarm.cpu.arn
        logs     = format("%s:*", module.logs["fis"].log_group.arn)
      }
    },
  ]
}
