### output variables

output "endpoint" {
  description = "The enpoints of Aurora cluster"
  value = {
    aurora = module.rds.endpoint
    proxy  = module.proxy.proxy.endpoint
  }
}

output "kubeconfig" {
  description = "Bash script to update kubeconfig file"
  value       = module.eks.kubeconfig
}

output "codebuild" {
  description = "Bash script to run the build projects using CodeBuild"
  value       = [for proj in values(module.ci) : proj.build]
}
