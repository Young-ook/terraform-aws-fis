### output variables

output "endpoint" {
  description = "The enpoints of Aurora cluster"
  value = {
    aurora = module.mysql.endpoint
    proxy  = module.proxy.proxy.endpoint
  }
}

output "kubeconfig" {
  description = "Bash script to update kubeconfig file"
  value       = module.eks.kubeconfig
}

output "build" {
  description = "Bash script to start build"
  value       = module.ci.build
}
