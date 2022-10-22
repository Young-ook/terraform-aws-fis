# security/firewall
resource "aws_security_group" "alb" {
  name   = join("-", [var.name, "alb"])
  tags   = var.tags
  vpc_id = var.vpc

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "alb_aware" {
  name   = join("-", [var.name, "alb", "aware"])
  tags   = var.tags
  vpc_id = var.vpc

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = [var.cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# application/loadbalancer
resource "aws_lb" "alb" {
  name                       = join("-", [var.name, "alb"])
  tags                       = var.tags
  internal                   = true
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.alb.id]
  subnets                    = var.subnets
  enable_deletion_protection = false
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.http.arn
  }
}

resource "aws_lb_target_group" "http" {
  depends_on                    = [aws_lb.alb]
  name                          = join("-", [var.name, "alb", "http"])
  tags                          = var.tags
  vpc_id                        = var.vpc
  port                          = 80
  protocol                      = "HTTP"
  target_type                   = "instance"
  load_balancing_algorithm_type = "least_outstanding_requests"
  deregistration_delay          = 10

  health_check {
    enabled  = true
    interval = 30
    path     = "/"
    port     = "traffic-port"
    protocol = "HTTP"
  }
}

# application/script
locals {
  server = join("\n", [
    "sudo yum update -y",
    "sudo yum install -y httpd",
    "sudo rm /etc/httpd/conf.d/welcome.conf",
    "sudo systemctl start httpd",
    ]
  )
}

# application/ec2
module "ec2" {
  source  = "Young-ook/ssm/aws"
  version = "1.0.3"
  name    = var.name
  tags    = var.tags
  subnets = (var.az == -1 ? var.subnets : [var.subnets[var.az]])
  node_groups = [
    {
      name              = "baseline"
      min_size          = 1
      max_size          = 6
      desired_size      = 1
      instance_type     = "t3.small"
      security_groups   = [aws_security_group.alb_aware.id]
      target_group_arns = [aws_lb_target_group.http.arn]
      tags              = { release = "baseline" }
      policy_arns       = ["arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"]
      user_data         = local.server
    },
    {
      name              = "canary"
      min_size          = 1
      max_size          = 1
      desired_size      = 1
      instance_type     = "t3.small"
      security_groups   = [aws_security_group.alb_aware.id]
      target_group_arns = [aws_lb_target_group.http.arn]
      tags              = { release = "canary" }
      policy_arns       = ["arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"]
      user_data         = local.server
    },
  ]
}

resource "aws_autoscaling_policy" "target-tracking" {
  name                   = join("-", [var.name, "target-tracking", "policy"])
  autoscaling_group_name = module.ec2.cluster.data_plane.node_groups.baseline.name
  adjustment_type        = "ChangeInCapacity"

  policy_type = "TargetTrackingScaling"
  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 10.0
  }
}

### monitoring/alarm
resource "aws_cloudwatch_metric_alarm" "cpu" {
  alarm_name                = join("-", [var.name, "cpu", "alarm"])
  alarm_description         = "This metric monitors ec2 cpu utilization"
  tags                      = var.tags
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
  tags                = var.tags
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
  tags                = var.tags
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
