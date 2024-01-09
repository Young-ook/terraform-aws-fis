### fault injection simulator experiment templates

### security/policy
resource "aws_iam_role" "fis-run" {
  name = join("-", [local.name, "fis-run"])
  tags = merge(local.default-tags, var.tags)
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = [format("fis.%s", local.aws.dns)]
      }
    }]
  })
}

resource "aws_iam_policy" "fis-pass-role" {
  name = join("-", [local.name, "fis-pass-role"])
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action   = ["iam:PassRole"],
      Effect   = "Allow"
      Resource = [aws_iam_role.fis-ssm-run.arn]
    }, ]
  })
}

resource "aws_iam_role_policy_attachment" "fis-pass-role" {
  policy_arn = aws_iam_policy.fis-pass-role.arn
  role       = aws_iam_role.fis-run.id
}

resource "aws_iam_role_policy_attachment" "fis-run" {
  policy_arn = format("arn:%s:iam::aws:policy/PowerUserAccess", local.aws.partition)
  role       = aws_iam_role.fis-run.id
}

resource "aws_iam_role" "fis-ssm-run" {
  name = join("-", [local.name, "fis-ssm-run"])
  tags = merge(local.default-tags, var.tags)
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = [format("ssm.%s", local.aws.dns)]
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "fis-ssm-vpcfull" {
  policy_arn = format("arn:%s:iam::aws:policy/AmazonVPCFullAccess", local.aws.partition)
  role       = aws_iam_role.fis-ssm-run.id
}

### fault injection experiment template

resource "awscc_fis_experiment_template" "exp" {
  for_each          = { for exp in var.experiments : exp.name => exp }
  tags              = merge(local.default-tags, { Name = each.key }, var.tags)
  description       = lookup(each.value, "description", null)
  role_arn          = aws_iam_role.fis-run.arn
  stop_conditions   = lookup(each.value, "stop_conditions", null)
  targets           = lookup(each.value, "targets", null)
  actions           = lookup(each.value, "actions", null)
  log_configuration = lookup(each.value, "log_configuration", null)
}

### systems manager document for fault injection simulator experiment

locals {
  doc = [
    {
      name            = "FIS-Run-AZ-Outage"
      document_format = "YAML"
      document_type   = "Automation"
      content         = file("${path.module}/templates/az-outage.yaml")
    },
    {
      name            = "FIS-Run-Disk-Stress"
      document_format = "YAML"
      document_type   = "Command"
      content         = file("${path.module}/templates/disk-stress.yaml")
    },
  ]
}

resource "aws_ssm_document" "doc" {
  for_each        = { for d in local.doc : d.name => d }
  name            = each.value["name"]
  tags            = merge(local.default-tags, var.tags)
  document_format = each.value["document_format"]
  document_type   = each.value["document_type"]
  content         = each.value["content"]
}
