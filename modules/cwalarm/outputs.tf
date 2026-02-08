### output variables

output "alarm" {
  description = "The attributes of generated metric alarm"
  value       = aws_cloudwatch_metric_alarm.alarm
}
