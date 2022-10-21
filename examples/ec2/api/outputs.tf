### output variables

output "server_group" {
  description = "Application server group"
  value       = module.ec2.cluster.data_plane.node_groups
}

output "role" {
  description = "Application role"
  value       = module.ec2.role.node_groups
}

output "alarms" {
  description = "Application alarms"
  value = {
    cpu = aws_cloudwatch_metric_alarm.cpu
  }
}

output "loadgen" {
  description = "Script to call APIs as a virtual client"
  value       = local.loadgen
}
