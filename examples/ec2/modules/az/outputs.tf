### output variables

output "az" {
  description = "Randomly selected availability zone"
  value       = var.azs[random_integer.az.result]
}

output "index" {
  description = "Index of Randomly selected availability zone"
  value       = random_integer.az.result
}
