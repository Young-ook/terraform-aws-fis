### monitoring/agent
resource "aws_ssm_association" "cwagent" {
  association_name = "SSM-StartCWAgent"
  name             = "AmazonCloudWatch-ManageAgent"
  parameters = {
    action = "start"
  }
  targets {
    key    = "tag:release"
    values = ["baseline", "canary"]
  }
}

### monitoring/alarm
resource "aws_cloudwatch_metric_alarm" "cpu" {
  alarm_name                = join("-", [var.name, "cpu", "alarm"])
  alarm_description         = "This metric monitors ec2 cpu utilization"
  tags                      = merge(local.default-tags, var.tags)
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = 3
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/EC2"
  period                    = 60
  statistic                 = "Average"
  threshold                 = 60
  insufficient_data_actions = []
  dimensions = {
    AutoScalingGroupName = module.ec2.cluster.data_plane.node_groups.baseline.name
  }
}

resource "aws_cloudwatch_metric_alarm" "api-p90" {
  alarm_name          = join("-", [var.name, "api-p90", "alarm"])
  alarm_description   = "This metric monitors percentile of response latency"
  tags                = merge(local.default-tags, var.tags)
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  unit                = "Seconds"
  threshold           = 0.1
  extended_statistic  = "p90"
  dimensions = {
    LoadBalancer = aws_lb.alb.arn_suffix
  }
}

resource "aws_cloudwatch_metric_alarm" "api-avg" {
  alarm_name          = join("-", [var.name, "api-avg", "alarm"])
  alarm_description   = "This metric monitors average time of response latency"
  tags                = merge(local.default-tags, var.tags)
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  unit                = "Seconds"
  statistic           = "Average"
  threshold           = 0.1
  dimensions = {
    LoadBalancer = aws_lb.alb.arn_suffix
  }
}

resource "aws_cloudwatch_metric_alarm" "api-http502" {
  alarm_name          = join("-", [var.name, "api-http502", "alarm"])
  alarm_description   = "This metric monitors HTTP 502 response from backed ec2 instances"
  tags                = merge(local.default-tags, var.tags)
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "HTTPCode_ELB_502_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  threshold           = 3
  dimensions = {
    LoadBalancer = aws_lb.alb.arn_suffix
  }
}
