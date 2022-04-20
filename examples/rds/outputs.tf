### output variables

output "endpoint" {
  description = "The enpoints of Aurora cluster"
  value       = module.mysql.endpoint
}
