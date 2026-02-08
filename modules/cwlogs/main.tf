### aws cloudwatch logs

### security/policy
resource "aws_iam_policy" "write" {
  name        = format("%s-logs-write", local.name)
  description = format("Allow to push and write logs to the cloudwatch logs")
  path        = "/"
  policy = jsonencode({
    Statement = [{
      Action = [
        "logs:CreateLogStream",
        "logs:DescribeLogStreams",
        "logs:PutLogEvents",
      ]
      Effect   = "Allow"
      Resource = [aws_cloudwatch_log_group.logs.arn]
    }]
    Version = "2012-10-17"
  })
}

### observability/log
resource "aws_cloudwatch_log_group" "logs" {
  name              = local.log_group_name
  tags              = merge(local.default-tags, var.tags)
  retention_in_days = lookup(local.log_group, "retension_days", 7)
}

resource "aws_cloudwatch_log_metric_filter" "filters" {
  for_each       = var.log_metric_filters != null ? { for k, v in var.log_metric_filters : k => v } : {}
  name           = lookup(each.value, "name", each.key)
  pattern        = lookup(each.value, "pattern", null)
  log_group_name = aws_cloudwatch_log_group.logs.name

  metric_transformation {
    name          = lookup(each.value, "name", null)
    namespace     = lookup(each.value, "namespace", null)
    value         = lookup(each.value, "value", 1)
    default_value = lookup(each.value, "default_value", null)
  }
}
