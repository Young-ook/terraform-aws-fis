### output variables

output "loadgen" {
  description = "Script to call APIs as a virtual client"
  value       = module.loadgen.script
}

output "random_az" {
  value = module.random-az.az
}

output "vpc_zone_identifier" {
  value = module.api["a"].vpc_zone_identifier
}
