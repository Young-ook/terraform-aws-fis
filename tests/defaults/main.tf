terraform {
  required_providers {
    test = {
      source = "terraform.io/builtin/test"
    }
  }
}

module "vpc" {
  source  = "Young-ook/vpc/aws"
  version = "1.0.3"
}

resource "aws_security_group" "sg" {
  name   = "fis-test-ec2-sg"
  vpc_id = module.vpc.vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [module.vpc.vpc.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

module "ec2" {
  source  = "Young-ook/ssm/aws"
  version = "1.0.5"
  subnets = slice(values(module.vpc.subnets["public"]), 0, 3)
  node_groups = [
    {
      name            = "test"
      desired_size    = 1
      instance_type   = "t3.small"
      security_groups = [aws_security_group.sg.id]
    },
  ]
}

resource "aws_cloudwatch_metric_alarm" "disk" {
  alarm_name          = "fis-test-cw-alarm"
  alarm_description   = "This metric monitors percentage of disk usage"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "disk_used_percent"
  namespace           = "CWAgent"
  period              = 60
  unit                = "Seconds"
  statistic           = "Average"
  threshold           = 60
  dimensions = {
    AutoScalingGroupName = module.ec2.cluster.data_plane.node_groups.test.name
  }
}

module "main" {
  source = "../.."
  experiments = [
    {
      name        = "ec2-disk-full"
      description = "Simulate disk full on ec2 instances"
      actions = {
        DiskFull = {
          action_id = "aws:ssm:send-command"
          targets   = { Instances = "ec2-instances" }
          parameters = {
            duration           = "PT5M"
            documentArn        = module.main.documents["FIS-Run-Disk-Stress"].arn
            documentParameters = "{\"DurationSeconds\": \"300\", \"Workers\": \"4\", \"Percent\": \"70\", \"InstallDependencies\": \"True\"}"
          }
        }
      }
      targets = {
        ec2-instances = {
          resource_type  = "aws:ec2:instance"
          resource_tags  = { release = "canary" }
          selection_mode = "PERCENT(70)"
        }
      }
      stop_conditions = [
        {
          source = "aws:cloudwatch:alarm",
          value  = aws_cloudwatch_metric_alarm.disk.arn
        }
      ]
    },
  ]
}
