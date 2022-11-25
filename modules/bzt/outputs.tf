### output variables

output "cluster" {
  description = "Server group"
  value       = module.ec2.cluster
}

output "role" {
  description = "Application role"
  value       = module.ec2.role.node_groups
}
