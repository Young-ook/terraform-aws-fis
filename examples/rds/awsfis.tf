# reliability/fis
module "awsfis" {
  source = "Young-ook/fis/aws"
  name   = var.name
  tags   = var.tags
  experiments = [
    {
      name     = "reboot-db-instances"
      template = "${path.cwd}/templates/reboot-db-instances.tpl"
      params = {
        region = var.aws_region
        db     = module.mysql.instances.0.arn
        alarm  = module.alarm["cpu"].alarm.arn
        logs   = format("%s:*", module.logs["fis"].log_group.arn)
        role   = module.awsfis.role.arn
      }
    },
    {
      name     = "failover-db-cluster"
      template = "${path.cwd}/templates/failover-db-cluster.tpl"
      params = {
        region  = var.aws_region
        cluster = module.mysql.cluster.arn
        alarm   = module.alarm["cpu"].alarm.arn
        logs    = format("%s:*", module.logs["fis"].log_group.arn)
        role    = module.awsfis.role.arn
      }
    },
  ]
}
