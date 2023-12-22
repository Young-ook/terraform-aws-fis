### aws partitions
module "aws" {
  source = "Young-ook/spinnaker/aws//modules/aws-partitions"
}

### security/policy
resource "aws_iam_role" "arh" {
  name = local.name
  tags = merge(local.default-tags, var.tags)
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = format("resiliencehub.%s", module.aws.partition.dns_suffix)
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "arh" {
  policy_arn = format("arn:%s:iam::aws:policy/AWSResilienceHubAsssessmentExecutionPolicy", module.aws.partition.partition)
  role       = aws_iam_role.arh.id
}

### dashboard
resource "awscc_resiliencehub_app" "app" {
  name                  = local.name
  tags                  = merge(local.default-tags, var.tags)
  app_template_body     = jsonencode(lookup(var.application, "components", ""))
  resource_mappings     = lookup(var.application, "resource_mappings", [])
  resiliency_policy_arn = awscc_resiliencehub_resiliency_policy.policy.policy_arn
  #  permission_model = {
  #    type                    = "RoleBased"
  #    invoker_role_name       = aws_iam_role.arh.id
  #    cross_account_role_arns = []
  #  }
}

### monitoring/policy
resource "awscc_resiliencehub_resiliency_policy" "policy" {
  policy_name = local.name
  tier        = lookup(var.policy == null ? {} : var.policy, "tier", local.default_policy.tier)
  policy = {
    AZ = {
      rto_in_secs = lookup(var.policy == null ? {} : var.policy, "rto", local.default_policy.rto)
      rpo_in_secs = lookup(var.policy == null ? {} : var.policy, "rpo", local.default_policy.rpo)
    }
    Hardware = {
      rto_in_secs = lookup(var.policy == null ? {} : var.policy, "rto", local.default_policy.rto)
      rpo_in_secs = lookup(var.policy == null ? {} : var.policy, "rpo", local.default_policy.rpo)
    }
    Software = {
      rto_in_secs = lookup(var.policy == null ? {} : var.policy, "rto", local.default_policy.rto)
      rpo_in_secs = lookup(var.policy == null ? {} : var.policy, "rpo", local.default_policy.rpo)
    }
    Region = {
      rto_in_secs = lookup(var.policy == null ? {} : var.policy, "rto", local.default_policy.rto)
      rpo_in_secs = lookup(var.policy == null ? {} : var.policy, "rpo", local.default_policy.rpo)
    }
  }
}
