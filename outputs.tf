### output variables

output "role" {
  description = "AWS FIS execution role"
  value = {
    fis = aws_iam_role.fis-run
    ssm = aws_iam_role.fis-ssm-run
  }
}

output "experiments" {
  description = "AWS FIS experiment template"
  value       = awscc_fis_experiment_template.exp
}

output "documents" {
  description = "Systems manager documents for fault injection experiment"
  value       = aws_ssm_document.doc
}
