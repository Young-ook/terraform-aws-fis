### output variables

output "random_az" {
  value = module.random-az.az
}

output "vpc_zone_identifier" {
  value = module.api["a"].vpc_zone_identifier
}
