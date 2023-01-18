### output variables

output "endpoint" {
  description = "The enpoints of Aurora cluster"
  value = {
    aurora = module.rds.endpoint
    proxy  = local.rdsproxy_enabled ? module.proxy["enabled"].proxy.endpoint : null
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

output "random_az" {
  value = module.random-az.item
}

output "vpc_zone_identifier" {
  value = module.ec2["a"].vpc_zone_identifier
}
