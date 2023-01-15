### fault injection simulator experiment templates

resource "random_integer" "az" {
  min = 0
  max = length(var.azs) - 1
}

module "awsfis" {
  source  = "Young-ook/fis/aws"
  version = "1.0.2"
  name    = var.name
  tags    = var.tags
  experiments = [
    {
      name     = "az-outage"
      template = "${path.cwd}/templates/az-outage.tpl"
      params = {
        az       = var.azs[random_integer.az.result]
        vpc      = module.vpc.vpc.id
        rds      = jsonencode([module.rds.cluster.arn])
        duration = "PT5M"
        logs     = format("%s:*", module.logs["fis"].log_group.arn)
        role     = module.awsfis.role["fis"].arn
        alarm = jsonencode([
          {
            "source" : "aws:cloudwatch:alarm",
            "value" : aws_cloudwatch_metric_alarm.cpu.arn
          },
          {
            "source" : "aws:cloudwatch:alarm",
            "value" : module.alarm["rds-cpu"].alarm.arn
          }
        ])
      }
    },
    {
      name     = "eks-pod-cpu"
      template = "${path.cwd}/templates/eks-pod-cpu.tpl"
      params = {
        eks   = module.eks.cluster["control_plane"].arn
        alarm = aws_cloudwatch_metric_alarm.cpu.arn
        role  = module.awsfis.role["fis"].arn
        logs  = format("%s:*", module.logs["fis"].log_group.arn)
      }
    },
    {
      name     = "eks-pod-kill"
      template = "${path.cwd}/templates/eks-pod-kill.tpl"
      params = {
        eks   = module.eks.cluster["control_plane"].arn
        alarm = aws_cloudwatch_metric_alarm.cpu.arn
        role  = module.awsfis.role["fis"].arn
        logs  = format("%s:*", module.logs["fis"].log_group.arn)
      }
    },
    {
      name     = "eks-pod-mem"
      template = "${path.cwd}/templates/eks-pod-mem.tpl"
      params = {
        eks   = module.eks.cluster["control_plane"].arn
        alarm = aws_cloudwatch_metric_alarm.cpu.arn
        role  = module.awsfis.role["fis"].arn
        logs  = format("%s:*", module.logs["fis"].log_group.arn)
      }
    },
    {
      name     = "eks-pod-netdelay"
      template = "${path.cwd}/templates/eks-pod-netdelay.tpl"
      params = {
        eks = module.eks.cluster["control_plane"].arn
        alarm = jsonencode([{
          source = "aws:cloudwatch:alarm"
          value  = aws_cloudwatch_metric_alarm.svc-health.arn
        }])
        role = module.awsfis.role["fis"].arn
        logs = format("%s:*", module.logs["fis"].log_group.arn)
      }
    },
    {
      name     = "ec2-netdelay"
      template = "${path.cwd}/templates/ec2-netdelay.tpl"
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
        targets = jsonencode({
          "chaos" = "ready"
        })
        alarm = jsonencode([{
          "source" : "aws:cloudwatch:alarm",
          "value" : aws_cloudwatch_metric_alarm.cpu.arn
        }])
        role = module.awsfis.role["fis"].arn
        logs = format("%s:*", module.logs["fis"].log_group.arn)
      }
    },
    {
      name     = "reboot-db-instances"
      template = "${path.cwd}/templates/reboot-db-instances.tpl"
      params = {
        region = var.aws_region
        db     = module.rds.instances.0.arn
        alarm  = module.alarm["rds-cpu"].alarm.arn
        logs   = format("%s:*", module.logs["fis"].log_group.arn)
        role   = module.awsfis.role["fis"].arn
      }
    },
    {
      name     = "failover-db-cluster"
      template = "${path.cwd}/templates/failover-db-cluster.tpl"
      params = {
        region  = var.aws_region
        cluster = module.rds.cluster.arn
        alarm   = module.alarm["rds-cpu"].alarm.arn
        logs    = format("%s:*", module.logs["fis"].log_group.arn)
        role    = module.awsfis.role["fis"].arn
      }
    },
  ]
}
