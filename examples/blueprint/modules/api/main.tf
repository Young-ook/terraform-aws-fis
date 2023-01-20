### security/firewall
resource "aws_security_group" "lb" {
  name   = join("-", [var.name, "lb"])
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

resource "aws_security_group" "lb_aware" {
  name   = join("-", [var.name, "lb", "aware"])
  tags   = var.tags
  vpc_id = var.vpc

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.lb.id]
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

### application/loadbalancer
resource "aws_lb" "lb" {
  name                       = join("-", [var.name, "lb"])
  tags                       = var.tags
  internal                   = true
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.lb.id]
  subnets                    = var.subnets
  enable_deletion_protection = false
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.lb.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.http.arn
  }
}

resource "aws_lb_target_group" "http" {
  depends_on                    = [aws_lb.lb]
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

### application/ec2
module "vm" {
  source  = "Young-ook/ssm/aws"
  version = "1.0.5"
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
      security_groups   = [aws_security_group.lb_aware.id]
      target_group_arns = [aws_lb_target_group.http.arn]
      tags              = { release = "baseline" }
      user_data         = templatefile("${path.module}/templates/server.tpl", {})
      policy_arns = [
        "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy",
        "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
        "arn:aws:iam::aws:policy/AWSAppMeshEnvoyAccess"
      ]
    },
    {
      name              = "canary"
      min_size          = 1
      max_size          = 1
      desired_size      = 1
      instance_type     = "t3.small"
      security_groups   = [aws_security_group.lb_aware.id]
      target_group_arns = [aws_lb_target_group.http.arn]
      tags              = { release = "canary" }
      user_data         = templatefile("${path.module}/templates/server.tpl", {})
      policy_arns = [
        "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy",
        "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
        "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess",
        "arn:aws:iam::aws:policy/AWSAppMeshEnvoyAccess"
      ]
    },
  ]
}

resource "aws_autoscaling_policy" "target-tracking" {
  name                   = join("-", [var.name, "target-tracking", "policy"])
  autoscaling_group_name = module.vm.cluster.data_plane.node_groups.baseline.name
  adjustment_type        = "ChangeInCapacity"

  policy_type = "TargetTrackingScaling"
  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 60.0
  }
}

### monitor/alarm
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
    AutoScalingGroupName = module.vm.cluster.data_plane.node_groups.baseline.name
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
    LoadBalancer = aws_lb.lb.arn_suffix
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
    LoadBalancer = aws_lb.lb.arn_suffix
  }
}

### network/dns
resource "aws_route53_record" "lb" {
  name    = var.name
  zone_id = var.dns
  type    = "A"
  alias {
    name                   = aws_lb.lb.dns_name
    zone_id                = aws_lb.lb.zone_id
    evaluate_target_health = true
  }
}
