### application/alarm
module "alarm" {
  source  = "Young-ook/eventbridge/aws//modules/alarm"
  version = "0.0.6"
  for_each = { for a in [
    {
      name        = "cpu"
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
              dimensions  = { DBClusterIdentifier = module.mysql.cluster.id }
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
  metric_query = each.value.metric_query
}

resource "aws_cloudwatch_metric_alarm" "cpu" {
  alarm_name                = join("-", [var.name, "cpu", "alarm"])
  alarm_description         = "This metric monitors ec2 cpu utilization"
  tags                      = merge(local.default-tags, var.tags)
  metric_name               = "node_cpu_utilization"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  datapoints_to_alarm       = 1
  evaluation_periods        = 1
  namespace                 = "ContainerInsights"
  period                    = 30
  threshold                 = 60
  statistic                 = "Average"
  insufficient_data_actions = []

  dimensions = {
    ClusterName = module.eks.cluster.name
  }
}

resource "aws_cloudwatch_metric_alarm" "disk" {
  alarm_name                = join("-", [var.name, "disk", "alarm"])
  alarm_description         = "This metric monitors ec2 disk filesystem usage"
  tags                      = merge(local.default-tags, var.tags)
  metric_name               = "node_filesystem_utilization"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  datapoints_to_alarm       = 1
  evaluation_periods        = 1
  namespace                 = "ContainerInsights"
  period                    = 30
  threshold                 = 60
  extended_statistic        = "p90"
  insufficient_data_actions = []

  dimensions = {
    ClusterName = module.eks.cluster.name
  }
}

resource "aws_cloudwatch_metric_alarm" "svc-health" {
  alarm_name                = join("-", [var.name, "svc", "health"])
  alarm_description         = "This metric monitors healty backed pods of a service"
  tags                      = merge(local.default-tags, var.tags)
  metric_name               = "service_number_of_running_pods"
  comparison_operator       = "LessThanThreshold"
  datapoints_to_alarm       = 1
  evaluation_periods        = 1
  namespace                 = "ContainerInsights"
  period                    = 10
  threshold                 = 1
  statistic                 = "Average"
  insufficient_data_actions = []

  dimensions = {
    Namespace   = "sockshop"
    Service     = "front-end"
    ClusterName = module.eks.cluster.name
  }
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
