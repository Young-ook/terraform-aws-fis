terraform {
  required_providers {
    test = {
      source = "terraform.io/builtin/test"
    }
  }
}

module "main" {
  source = "../../"
  for_each = { for a in [
    {
      name = "tc1"
      alarm_metric = {
        threshold = 1
      }
      metric_query = [
        {
          id          = "service_num_of_running_pods"
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
    },
    {
      name = "tc2"
      alarm_metric = {
        # comparison_operator. following is supported:
        #   GreaterThanOrEqualToThreshold
        #   GreaterThanThreshold
        #   LessThanThreshold
        #   LessThanOrEqualToThreshold
        comparison_operator = "LessThanThreshold"
        datapoints_to_alarm = 1
        evaluation_periods  = 1
        threshold           = 1
      }
      metric_query = [
        {
          id          = "service_num_of_running_pods"
          return_data = true
          metric = [
            {
              metric_name = "service_number_of_running_pods"
              namespace   = "ContainerInsights"
              period      = "10"
              stat        = "Average"
              dimensions = {
                Namespace   = "sockshop"
                Service     = "front-end"
                ClusterName = "MyCluster"
              }
            },
          ]
        },
      ]
    },
    {
      name = "tc3"
      alarm_metric = {
        # comparison_operator. following is supported:
        #   GreaterThanOrEqualToThreshold
        #   GreaterThanThreshold
        #   LessThanThreshold
        #   LessThanOrEqualToThreshold
        comparison_operator = "GreaterThanOrEqualToThreshold"
        evaluation_periods  = 10
      }
      metric_query = [
        {
          id          = "elb_num_of_http502"
          return_data = true
          metric = [
            {
              metric_name = "HTTPCode_ELB_502_Count"
              namespace   = "AWS/ApplicationELB"
              period      = "60"
              stat        = "Sum"
              dimensions = {
                LoadBalancer = "MyLB"
              }
            },
          ]
        },
      ]
    },
    {
      name = "tc4"
      alarm_metric = {
        comparison_operator = "GreaterThanOrEqualToThreshold"
        evaluation_periods  = 1
        datapoints_to_alarm = 1
        threshold           = 60
        extended_statistic  = "p90"
        metric_name         = "TargetResponseTime"
        namespace           = "AWS/ApplicationELB"
        dimensions          = { LoadBalancer = "MyLB" }
      }
      metric_query = []
    },
  ] : a.name => a }
  alarm_metric = lookup(each.value, "alarm_metric")
  metric_query = lookup(each.value, "metric_query")
}
