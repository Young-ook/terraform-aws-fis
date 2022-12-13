### fault injection simulator experiment templates

resource "random_integer" "az" {
  min = 0
  max = length(var.azs) - 1
}

module "awsfis" {
  source = "Young-ook/fis/aws"
  name   = var.name
  tags   = var.tags
  experiments = [
    {
      name     = "az-outage"
      template = "${path.cwd}/templates/az-outage.tpl"
      params = {
        az       = var.azs[random_integer.az.result]
        vpc      = module.vpc.vpc.id
        duration = "PT1M"
        fis_role = module.awsfis.role["fis"].arn
        alarm    = aws_cloudwatch_metric_alarm.cpu.arn
        logs     = format("%s:*", module.logs["fis"].log_group.arn)
      }
    },
    {
      name     = "cpu-stress"
      template = "${path.cwd}/templates/cpu-stress.tpl"
      params = {
        eks   = module.eks.cluster["control_plane"].arn
        alarm = aws_cloudwatch_metric_alarm.cpu.arn
        role  = module.awsfis.role["fis"].arn
        logs  = format("%s:*", module.logs["fis"].log_group.arn)
      }
    },
    {
      name     = "network-latency"
      template = "${path.cwd}/templates/network-latency.tpl"
      params = {
        region = var.aws_region
        alarm  = aws_cloudwatch_metric_alarm.svc-health.arn
        role   = module.awsfis.role["fis"].arn
        logs   = format("%s:*", module.logs["fis"].log_group.arn)
      }
    },
    {
      name     = "throttle-ec2-api"
      template = "${path.cwd}/templates/throttle-ec2-api.tpl"
      params = {
        asg_role = module.eks.role.managed_node_groups.arn
        alarm    = aws_cloudwatch_metric_alarm.cpu.arn
        role     = module.awsfis.role["fis"].arn
        logs     = format("%s:*", module.logs["fis"].log_group.arn)
      }
    },
    {
      name     = "terminate-eks-nodes"
      template = "${path.cwd}/templates/terminate-eks-nodes.tpl"
      params = {
        az        = var.azs[random_integer.az.result]
        vpc       = module.vpc.vpc.id
        nodegroup = module.eks.cluster.data_plane.managed_node_groups.apps.arn
        role      = module.awsfis.role["fis"].arn
        logs      = format("%s:*", module.logs["fis"].log_group.arn)
        alarm = jsonencode([
          {
            source = "aws:cloudwatch:alarm"
            value  = aws_cloudwatch_metric_alarm.cpu.arn
          },
          {
            source = "aws:cloudwatch:alarm"
            value  = aws_cloudwatch_metric_alarm.svc-health.arn
        }])
      }
    },
    {
      name     = "disk-stress"
      template = "${path.cwd}/templates/disk-stress.tpl"
      params = {
        doc_arn = module.awsfis.experiment["FIS-Run-Disk-Stress"].arn
        alarm   = aws_cloudwatch_metric_alarm.disk.arn
        role    = module.awsfis.role["fis"].arn
        logs    = format("%s:*", module.logs["fis"].log_group.arn)
      }
    },
    {
      name     = "interrupt-spot-instances"
      template = "${path.cwd}/templates/interrupt-spot-instances.tpl"
      params = {
        targets = jsonencode([
          {
            "chaos" = "ready"
          },
        ])
        alarm = aws_cloudwatch_metric_alarm.cpu.arn
        role  = module.awsfis.role["fis"].arn
        logs  = format("%s:*", module.logs["fis"].log_group.arn)
      }
    },
    {
      name     = "reboot-db-instances"
      template = "${path.cwd}/templates/reboot-db-instances.tpl"
      params = {
        region = var.aws_region
        db     = module.mysql.instances.0.arn
        alarm  = module.alarm["cpu"].alarm.arn
        logs   = format("%s:*", module.logs["fis"].log_group.arn)
        role   = module.awsfis.role["fis"].arn
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
        role    = module.awsfis.role["fis"].arn
      }
    },
  ]
}
