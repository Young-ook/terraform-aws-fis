# application/monitoring
resource "aws_cloudwatch_metric_alarm" "cpu" {
  alarm_name                = join("-", [var.name, "cpu", "alarm"])
  alarm_description         = "This metric monitors rds cpu utilization"
  tags                      = merge(local.default-tags, var.tags)
  metric_name               = "CPUUtilization"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  datapoints_to_alarm       = 1
  evaluation_periods        = 1
  namespace                 = "AWS/RDS"
  period                    = 60
  threshold                 = 60
  statistic                 = "Average"
  insufficient_data_actions = []

  dimensions = {
    DBClusterIdentifier = module.mysql.cluster.id
  }
}

# application/logs
module "logs" {
  source  = "Young-ook/lambda/aws//modules/logs"
  version = "0.2.1"
  for_each = { for l in [
    {
      type = "codebuild"
      log_group = {
        namespace      = "/aws/codebuild"
        retension_days = 5
      }
    },
  ] : l.type => l }
  name      = join("-", [var.name, each.key])
  log_group = each.value.log_group
}
