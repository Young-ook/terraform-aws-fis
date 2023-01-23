### fault injection simulator experiment templates

module "random-az" {
  source = "../../modules/roulette"
  items  = var.azs
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
        actions = jsonencode({
          "AZOutage" = {
            "actionId"    = "aws:network:disrupt-connectivity"
            "description" = "Block all EC2 traffics from and to the subnets"
            "parameters" = {
              "duration" = "PT5M"
              "scope"    = "availability-zone"
            },
            "targets" = {
              "Subnets" = module.random-az.item
            }
          }
          "FailOverCluster" = {
            "actionId"    = "aws:rds:failover-db-cluster"
            "description" = "Failover Aurora cluster"
            "parameters"  = {}
            "targets" = {
              "Clusters" = "rds-cluster"
            }
          }
        })
        targets = jsonencode({
          var.azs[module.random-az.index] = {
            "resourceType" = "aws:ec2:subnet"
            "parameters" = {
              "availabilityZoneIdentifier" = module.random-az.item
              "vpc"                        = module.vpc.vpc.id
            }
            "selectionMode" = "ALL"
          }
          "rds-cluster" = {
            "resourceType"  = "aws:rds:cluster"
            "resourceArns"  = [module.rds.cluster.arn]
            "selectionMode" = "ALL"
          }
        })
        alarms = jsonencode([
          {
            "source" = "aws:cloudwatch:alarm",
            "value"  = aws_cloudwatch_metric_alarm.eks-cpu.arn
          },
          {
            "source" = "aws:cloudwatch:alarm",
            "value"  = module.alarm["rds-cpu"].alarm.arn
          }
        ])
        logs = format("%s:*", module.logs["fis"].log_group.arn)
        role = module.awsfis.role["fis"].arn
      }
    },
    {
      name     = "eks-pod-cpu"
      template = "${path.cwd}/templates/eks-pod-cpu.tpl"
      params = {
        eks   = module.eks.cluster["control_plane"].arn
        alarm = aws_cloudwatch_metric_alarm.eks-cpu.arn
        role  = module.awsfis.role["fis"].arn
        logs  = format("%s:*", module.logs["fis"].log_group.arn)
      }
    },
    {
      name     = "eks-pod-kill"
      template = "${path.cwd}/templates/eks-pod-kill.tpl"
      params = {
        eks   = module.eks.cluster["control_plane"].arn
        alarm = aws_cloudwatch_metric_alarm.eks-cpu.arn
        role  = module.awsfis.role["fis"].arn
        logs  = format("%s:*", module.logs["fis"].log_group.arn)
      }
    },
    {
      name     = "eks-pod-mem"
      template = "${path.cwd}/templates/eks-pod-mem.tpl"
      params = {
        eks   = module.eks.cluster["control_plane"].arn
        alarm = aws_cloudwatch_metric_alarm.eks-cpu.arn
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
      name     = "terminate-eks-nodes"
      template = "${path.cwd}/templates/terminate-eks-nodes.tpl"
      params = {
        az        = module.random-az.item
        vpc       = module.vpc.vpc.id
        nodegroup = module.eks.cluster.data_plane.managed_node_groups.apps.arn
        role      = module.awsfis.role["fis"].arn
        logs      = format("%s:*", module.logs["fis"].log_group.arn)
        alarm = jsonencode([
          {
            source = "aws:cloudwatch:alarm"
            value  = aws_cloudwatch_metric_alarm.eks-cpu.arn
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
        alarm   = aws_cloudwatch_metric_alarm.eks-disk.arn
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
          "value" : aws_cloudwatch_metric_alarm.eks-cpu.arn
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
    {
      name     = "ec2-api-throttle"
      template = "${path.cwd}/templates/ec2-api-throttle.tpl"
      params = {
        actions = jsonencode({
          "ThrottleAPI" = {
            "actionId"    = "aws:fis:inject-api-throttle-error",
            "description" = "Throttle AWS APIs for describing EC2 instances",
            "targets"     = { "Roles" : "ec2" }
            "parameters" = {
              "service"    = "ec2",
              "operations" = "DescribeInstances,DescribeVolumes",
              "percentage" = "90",
              "duration"   = "PT2M"
            },
          }
        })
        targets = jsonencode({
          "ec2" = {
            "resourceType"  = "aws:iam:role",
            "resourceArns"  = [module.ec2["a"].role.canary.arn]
            "selectionMode" = "ALL"
          }
        })
        alarms = jsonencode([
          {
            "source" = "aws:cloudwatch:alarm",
            "value"  = module.ec2["a"].alarms.cpu.arn
          },
        ])
        logs = format("%s:*", module.logs["fis"].log_group.arn)
        role = module.awsfis.role["fis"].arn
      }
    },
    {
      name     = "ec2-api-error"
      template = "${path.cwd}/templates/ec2-api-error.tpl"
      params = {
        actions = jsonencode({
          "AwsApiInternalError" = {
            "actionId"    = "aws:fis:inject-api-internal-error",
            "description" = "AWS API internal error when describing EC2 instances",
            "targets"     = { "Roles" : "ec2" }
            "parameters" = {
              "service"    = "ec2",
              "operations" = "AllocateAddress,AssignPrivateIpAddresses,DescribeVolumes",
              "percentage" = "100",
              "duration"   = "PT2M"
            },
          }
        })
        targets = jsonencode({
          "ec2" = {
            "resourceType"  = "aws:iam:role",
            "resourceArns"  = [module.ec2["a"].role.canary.arn]
            "selectionMode" = "ALL"
          }
        })
        alarms = jsonencode([
          {
            "source" = "aws:cloudwatch:alarm",
            "value"  = module.ec2["a"].alarms.cpu.arn
          },
        ])
        logs = format("%s:*", module.logs["fis"].log_group.arn)
        role = module.awsfis.role["fis"].arn
      }
    },
  ]
}
