### fault injection experiment template

resource "awscc_fis_experiment_template" "exp" {
  tags            = merge(local.default-tags, var.tags)
  description     = var.description
  role_arn        = var.role
  stop_conditions = var.stop_conditions
  targets         = var.targets
  actions         = var.actions
}
