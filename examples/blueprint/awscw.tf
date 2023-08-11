### application/alarm
module "alarm" {
  source  = "Young-ook/eventbridge/aws//modules/alarm"
  version = "0.0.13"
  for_each = { for a in [
    {
      name        = "rds-cpu"
      description = "This metric monitors rds cpu utilization"
      alarm_metric = {
        comparison_operator = "GreaterThanOrEqualToThreshold"
        evaluation_periods  = 1
        datapoints_to_alarm = 1
        threshold           = 60
      }
      metric_query = [
        {
          id          = "rds_cpu_high"
          return_data = true
          metric = [
            {
              metric_name = "CPUUtilization"
              namespace   = "AWS/RDS"
              stat        = "Average"
              period      = 60
              dimensions  = { DBClusterIdentifier = module.rds.cluster.id }
            },
          ]
        },
      ]
    },
    {
      name        = "eks-cpu"
      description = "This metric monitors eks node cpu utilization"
      alarm_metric = {
        comparison_operator = "GreaterThanOrEqualToThreshold"
        evaluation_periods  = 1
        datapoints_to_alarm = 1
        threshold           = 60
      }
      metric_query = [
        {
          id          = "eks_cpu_high"
          return_data = true
          metric = [
            {
              metric_name = "node_cpu_utilization"
              namespace   = "ContainerInsights"
              stat        = "Average"
              period      = 30
              dimensions  = { ClusterName = module.eks.cluster.name }
            },
          ]
        },
      ]
    },
    {
      name        = "eks-disk"
      description = "This metric monitors ec2 disk filesystem usage"
      alarm_metric = {
        comparison_operator = "GreaterThanOrEqualToThreshold"
        extended_statistic  = "p90"
        evaluation_periods  = 1
        datapoints_to_alarm = 1
        period              = 30
        threshold           = 60
        metric_name         = "node_filesystem_utilization"
        namespace           = "ContainerInsights"
        dimensions          = { ClusterName = module.eks.cluster.name }
      }
    },
    {
      name        = "svc-health"
      description = "This metric monitors healty backed pods of a service"
      alarm_metric = {
        comparison_operator = "LessThanThreshold"
        evaluation_periods  = 1
        datapoints_to_alarm = 1
        threshold           = 1
      }
      metric_query = [
        {
          id          = "runnung_pods"
          return_data = true
          metric = [
            {
              metric_name = "service_number_of_running_pods"
              namespace   = "ContainerInsights"
              stat        = "Average"
              period      = 10
              dimensions = {
                Namespace   = "sockshop"
                Service     = "front-end"
                ClusterName = module.eks.cluster.name
              }
            },
          ]
        },
      ]
    },
  ] : a.name => a }
  name         = join("-", [each.key, "alarm"])
  tags         = merge(local.default-tags, var.tags)
  description  = each.value.description
  alarm_metric = each.value.alarm_metric
  metric_query = try(each.value.metric_query, null)
}

### application/logs
module "logs" {
  source  = "Young-ook/eventbridge/aws//modules/logs"
  version = "0.0.6"
  for_each = { for l in [
    {
      type = "codebuild"
      log_group = {
        namespace      = "/aws/codebuild"
        retension_days = 5
      }
    },
    {
      type = "fis"
      log_group = {
        namespace      = "/aws/fis"
        retension_days = 3
      }
    },
    {
      type = "redis"
      log_group = {
        namespace      = "/aws/elasticache"
        retension_days = 3
      }
    },
  ] : l.type => l }
  name      = join("-", [var.name, each.key])
  log_group = each.value.log_group
}
