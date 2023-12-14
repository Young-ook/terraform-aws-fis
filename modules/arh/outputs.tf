### output variables

output "role" {
  description = "The generated role for the AWS Resilience Hub"
  value       = aws_iam_role.arh
}
