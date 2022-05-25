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
      name     = "cpu-stress"
      template = "${path.cwd}/templates/cpu-stress.tpl"
      params = {
        region = var.aws_region
        asg    = module.ec2.cluster.data_plane.node_groups.canary.name
        alarm  = aws_cloudwatch_metric_alarm.cpu.arn
        role   = module.awsfis.role["fis"].arn
        logs   = format("%s:*", module.logs["fis"].log_group.arn)
      }
    },
    {
      name     = "disk-stress"
      template = "${path.cwd}/templates/disk-stress.tpl"
      params = {
        doc_arn = module.awsfis.experiment["FIS-Run-Disk-Stress"].arn
        region  = var.aws_region
        asg     = module.ec2.cluster.data_plane.node_groups.canary.name
        alarm   = aws_cloudwatch_metric_alarm.cpu.arn
        role    = module.awsfis.role["fis"].arn
        logs    = format("%s:*", module.logs["fis"].log_group.arn)
      }
    },
    {
      name     = "network-latency"
      template = "${path.cwd}/templates/network-latency.tpl"
      params = {
        region = var.aws_region
        asg    = module.ec2.cluster.data_plane.node_groups.canary.name
        alarm  = aws_cloudwatch_metric_alarm.cpu.arn
        role   = module.awsfis.role["fis"].arn
        logs   = format("%s:*", module.logs["fis"].log_group.arn)
      }
    },
    {
      name     = "terminate-instances"
      template = "${path.cwd}/templates/terminate-instances.tpl"
      params = {
        asg   = module.ec2.cluster.data_plane.node_groups.baseline.name
        az    = var.azs[random_integer.az.result]
        vpc   = module.vpc.vpc.id
        alarm = aws_cloudwatch_metric_alarm.cpu.arn
        role  = module.awsfis.role["fis"].arn
        logs  = format("%s:*", module.logs["fis"].log_group.arn)
      }
    },
    {
      name     = "throttle-ec2-api"
      template = "${path.cwd}/templates/throttle-ec2-api.tpl"
      params = {
        asg_role = module.ec2.role.node_groups.canary.arn
        alarm    = aws_cloudwatch_metric_alarm.cpu.arn
        role     = module.awsfis.role["fis"].arn
        logs     = format("%s:*", module.logs["fis"].log_group.arn)
      }
    },
    {
      name     = "kill-process"
      template = "${path.cwd}/templates/kill-process.tpl"
      params = {
        region  = var.aws_region
        asg     = module.ec2.cluster.data_plane.node_groups.baseline.name
        az      = var.azs[random_integer.az.result]
        process = "httpd"
        alarm   = aws_cloudwatch_metric_alarm.cpu.arn
        role    = module.awsfis.role["fis"].arn
        logs    = format("%s:*", module.logs["fis"].log_group.arn)
      }
    },
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
