# application/alarm
module "alarm" {
  source  = "Young-ook/lambda/aws//modules/alarm"
  version = "0.2.1"
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
