### output variables

output "log_group" {
  description = "The attributes of generated log group"
  value       = aws_cloudwatch_log_group.logs
}

output "policy_arns" {
  description = "A map of IAM polices to allow access this log group. If you want to make an IAM role or instance-profile has permissions to manage this repository, please attach the `poliy_arn` of this output on your side."
  value       = zipmap(["write"], [aws_iam_policy.write.arn])
}

output "log_metric_filters" {
  description = "The log metric transform filters"
  value       = aws_cloudwatch_log_metric_filter.filters
}
