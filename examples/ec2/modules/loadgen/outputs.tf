### output variables

output "server_group" {
  description = "Application server group"
  value       = module.ec2.cluster.data_plane.node_groups
}

output "role" {
  description = "Application role"
  value       = module.ec2.role.node_groups
}
