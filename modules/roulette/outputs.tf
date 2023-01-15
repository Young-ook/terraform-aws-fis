### output variables

output "item" {
  description = "Randomly selected item"
  value       = var.items[random_integer.roulette.result]
}

output "index" {
  description = "Index of randomly selected item"
  value       = random_integer.roulette.result
}
