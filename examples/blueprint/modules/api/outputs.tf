### output variables

output "load_balancer" {
  description = "API load balancer dns name"
  value       = aws_route53_record.lb.fqdn
}

output "server_group" {
  description = "Application server group"
  value       = module.vm.cluster.data_plane.node_groups
}

output "role" {
  description = "Application role"
  value       = module.vm.role.node_groups
}

output "security_group" {
  description = "Security group for application server group"
  value       = aws_security_group.lb_aware
}

output "alarms" {
  description = "Application alarms"
  value = {
    cpu     = aws_cloudwatch_metric_alarm.cpu,
    api-p90 = aws_cloudwatch_metric_alarm.api-p90
  }
}

output "vpc_zone_identifier" {
  description = "VPC subnets where ec2 instance are deployed"
  value       = (var.az == -1 ? var.subnets : [var.subnets[var.az]])
}
