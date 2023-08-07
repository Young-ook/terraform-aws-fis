### fault injection experiment template

resource "awscc_fis_experiment_template" "exp" {
  for_each        = { for template in var.templates : template.name => template }
  tags            = merge(local.default-tags, { Name = each.key }, var.tags)
  description     = lookup(each.value, "description", null)
  role_arn        = lookup(each.value, "role", null)
  stop_conditions = lookup(each.value, "stop_conditions", null)
  targets         = lookup(each.value, "targets", null)
  actions         = lookup(each.value, "actions", null)
}
