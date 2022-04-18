### output variables

output "role" {
  description = "AWS FIS execution role"
  value       = aws_iam_role.fis-run
}
