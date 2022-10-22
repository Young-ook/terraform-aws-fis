### output variables

output "loadgen" {
  description = "Script to call APIs as a virtual client"
  value       = module.api["a"].loadgen
}

output "random_az" {
  value = module.random-az.az
}
