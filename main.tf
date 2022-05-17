### fault injection simulator experiment templates

module "aws" {
  source = "Young-ook/spinnaker/aws//modules/aws-partitions"
}

locals {
  aws = {
    dns       = module.aws.partition.dns_suffix
    partition = module.aws.partition.partition
    region    = module.aws.region.name
  }
}

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
      },]
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

resource "local_file" "exp" {
  for_each        = { for exp in var.experiments : exp.name => exp }
  content         = templatefile(lookup(each.value, "template"), lookup(each.value, "params", {}))
  filename        = join("/", [path.module, format("%s.json", each.key)])
  file_permission = "0600"
}

locals {
  cli = [
    {
      in  = "awsfis-init.tpl"
      out = "awsfis-init.sh"
      params = {
        region   = local.aws.region
        explist  = join("/", [path.cwd, ".fis_cli_result"])
        jsonlist = trimsuffix(join(".json ", concat(keys({ for exp in var.experiments : exp.name => exp }), [""])), " ")
      }
    },
    {
      in  = "awsfis-cleanup.tpl"
      out = "awsfis-cleanup.sh"
      params = {
        region  = local.aws.region
        explist = join("/", [path.cwd, ".fis_cli_result"])
      }
    },
  ]
}

resource "local_file" "cli" {
  for_each = { for k, v in local.cli : k => v }
  content = templatefile(
    join("/", [path.module, "templates", lookup(each.value, "in")]),
    lookup(each.value, "params", {})
  )
  filename        = join("/", [path.module, lookup(each.value, "out")])
  file_permission = "0600"
}

resource "null_resource" "awsfis-init" {
  depends_on = [local_file.exp, local_file.cli]
  provisioner "local-exec" {
    when    = create
    command = "cd ${path.module} \n bash awsfis-init.sh"
  }
}

resource "null_resource" "awsfis-cleanup" {
  depends_on = [local_file.exp, local_file.cli]
  provisioner "local-exec" {
    when    = destroy
    command = "cd ${path.module} \n bash awsfis-cleanup.sh"
  }
}

### systems manager document for fault injection simulator experiment

resource "aws_ssm_document" "az-outage" {
  name            = "FIS-Run-AZ-Outage"
  tags            = merge(local.default-tags, var.tags)
  document_format = "YAML"
  document_type   = "Automation"
  content         = file("${path.module}/templates/az-outage.yaml")
}


