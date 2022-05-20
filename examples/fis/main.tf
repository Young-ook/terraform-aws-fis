provider "aws" {
  region = var.aws_region
}

# application/alarm
module "stop" {
  source = "Young-ook/lambda/aws//modules/alarm"
  name   = var.name
  alarm_metric = {
    comparison_operator = "GreaterThanThreshold"
    datapoints_to_alarm = 1
    evaluation_periods  = 1
    threshold           = 1
  }
  metric_query = [
    {
      id          = "cpu_high"
      return_data = true
      metric = [
        {
          metric_name = "CPUUtilization"
          namespace   = "AWS/EC2"
          period      = "60"
          stat        = "Average"
          dimensions = {
            AutoScalingGroupName = "MyASG"
          }
        },
      ]
    },
  ]
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

# platform/fis
module "fis" {
  source = "../../"
  name   = var.name
  tags   = var.tags
  experiments = [
    {
      name     = "cpu-stress"
      template = "${path.cwd}/templates/cpu-stress.tpl"
      params = {
        region = var.aws_region
        alarm  = module.stop.alarm.arn
        role    = module.awsfis.role["fis"].arn
        logs    = format("%s:*", module.logs["fis"].log_group.arn)
      }
    },
  ]
}
