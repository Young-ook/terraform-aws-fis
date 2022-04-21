### output variables

output "endpoint" {
  description = "The enpoints of Aurora cluster"
  value       = module.mysql.endpoint
}

output "kubeconfig" {
  description = "Bash script to update kubeconfig file"
  value       = module.eks.kubeconfig
}
