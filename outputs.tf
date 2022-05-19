### output variables

output "role" {
  description = "AWS FIS execution role"
  value = {
    fis = aws_iam_role.fis-run
    ssm = aws_iam_role.fis-ssm-run
  }
}

output "experiment" {
  description = "Systems manager documents for experiments "
  value = {
    az-outage = aws_ssm_document.az-outage
  }
}
