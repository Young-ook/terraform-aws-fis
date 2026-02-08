### observability/alarm
resource "aws_cloudwatch_metric_alarm" "alarm" {
  alarm_name        = local.name
  alarm_description = var.description
  tags              = merge(local.default-tags, var.tags)

  # alarm condition
  comparison_operator                   = lookup(var.alarm_metric, "comparison_operator", "GreaterThanThreshold")
  treat_missing_data                    = lookup(var.alarm_metric, "treat_missing_data", "missing")
  datapoints_to_alarm                   = lookup(var.alarm_metric, "datapoints_to_alarm", null)
  threshold                             = lookup(var.alarm_metric, "threshold", 1)
  evaluation_periods                    = lookup(var.alarm_metric, "evaluation_periods", 1)
  period                                = lookup(var.alarm_metric, "period", null)
  evaluate_low_sample_count_percentiles = lookup(var.alarm_metric, "evaluate_low_sample_count_percentiles", null)
  metric_name                           = lookup(var.alarm_metric, "metric_name", null)
  namespace                             = lookup(var.alarm_metric, "namespace", null)
  extended_statistic                    = lookup(var.alarm_metric, "extended_statistic", null)
  statistic                             = lookup(var.alarm_metric, "statistic", null)

  # alarm actions
  actions_enabled           = lookup(var.alarm_actions, "actions_enabled", false)
  alarm_actions             = lookup(var.alarm_actions, "alarm_actions", [])
  ok_actions                = lookup(var.alarm_actions, "ok_actions", [])
  insufficient_data_actions = lookup(var.alarm_actions, "insufficient_data_actions", [])

  # metric query
  dynamic "metric_query" {
    for_each = (var.metric_query == null) ? [] : var.metric_query
    content {
      id          = lookup(metric_query.value, "id")
      label       = lookup(metric_query.value, "label", null)
      return_data = lookup(metric_query.value, "return_data", false)
      expression  = lookup(metric_query.value, "expression", null)

      dynamic "metric" {
        for_each = lookup(metric_query.value, "metric", [])
        content {
          metric_name = lookup(metric.value, "metric_name")
          namespace   = lookup(metric.value, "namespace")
          period      = lookup(metric.value, "period")
          stat        = lookup(metric.value, "stat")
          unit        = lookup(metric.value, "unit", null)
          dimensions  = lookup(metric.value, "dimensions", null)
        }
      }
    }
  }
}
