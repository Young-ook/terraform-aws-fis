provider "aws" {
  region = var.aws_region
}

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
        role   = module.fis.role.arn
      }
    },
  ]
}
