# application/monitoring
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
