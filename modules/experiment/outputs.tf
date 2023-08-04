### output variables

output "experiment" {
  description = "AWS FIS experiment template"
  value       = awscc_fis_experiment_template.exp
}
