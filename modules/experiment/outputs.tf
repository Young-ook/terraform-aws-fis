### output variables

output "json" {
  description = "AWS FIS experiment JSON template"
  value = jsonencode(
    {
      actions          = var.actions
      description      = var.description
      logConfiguration = var.logs
      tags             = merge(var.tags, local.default-tags)
      targets          = var.targets
      roleArn          = var.role
      stopConditions   = var.stop_conditions == null ? [{ source = "none" }] : var.stop_conditions
    }
  )
}
