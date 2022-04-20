
### systems manager document for fault injection simulator experiment

resource "aws_ssm_document" "disk-stress" {
  name            = "FIS-Run-Disk-Stress"
  tags            = merge(local.default-tags, var.tags)
  document_format = "YAML"
  document_type   = "Command"
  content         = file("${path.cwd}/templates/disk-stress.yaml")
}

resource "random_integer" "az" {
  min = 0
  max = length(var.azs) - 1
}

module "awsfis" {
  source = "Young-ook/fis/aws"
  name   = var.name
  tags   = var.tags
  experiments = [
    {
      name     = "cpu-stress"
      template = "${path.cwd}/templates/cpu-stress.tpl"
      params = {
        region = var.aws_region
        alarm  = aws_cloudwatch_metric_alarm.cpu.arn
        role   = module.awsfis.role.arn
      }
    },
    {
      name     = "network-latency"
      template = "${path.cwd}/templates/network-latency.tpl"
      params = {
        region = var.aws_region
        alarm  = aws_cloudwatch_metric_alarm.svc-health.arn
        role   = module.awsfis.role.arn
      }
    },
    {
      name     = "throttle-ec2-api"
      template = "${path.cwd}/templates/throttle-ec2-api.tpl"
      params = {
        asg_role = module.eks.role.arn
        alarm    = aws_cloudwatch_metric_alarm.cpu.arn
        role     = module.awsfis.role.arn
      }
    },
    {
      name     = "terminate-eks-nodes"
      template = "${path.cwd}/templates/terminate-eks-nodes.tpl"
      params = {
        az        = var.azs[random_integer.az.result]
        vpc       = module.vpc.vpc.id
        nodegroup = module.eks.cluster.data_plane.managed_node_groups.sockshop.arn
        role      = module.awsfis.role.arn
        alarm = jsonencode([
          {
            source = "aws:cloudwatch:alarm"
            value  = aws_cloudwatch_metric_alarm.cpu.arn
          },
          {
            source = "aws:cloudwatch:alarm"
            value  = aws_cloudwatch_metric_alarm.svc-health.arn
        }])
      }
    },
    {
      name     = "disk-stress"
      template = "${path.cwd}/templates/disk-stress.tpl"
      params = {
        doc_arn = aws_ssm_document.disk-stress.arn
        alarm   = aws_cloudwatch_metric_alarm.disk.arn
        role    = module.awsfis.role.arn
      }
    },
  ]

}
