### application/loadgen
module "ec2" {
  source  = "Young-ook/ssm/aws"
  version = "1.0.5"
  name    = var.name
  tags    = var.tags
  subnets = var.subnets
  node_groups = [
    {
      name            = "tester"
      min_size        = 1
      max_size        = 1
      desired_size    = 1
      instance_type   = "t3.small"
      security_groups = var.security_groups
      user_data = templatefile("${path.module}/templates/taurus.tpl", {
        config = var.config
        task   = var.task
      })
      policy_arns = ["arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"]
    }
  ]
}
