### frigga name
module "frigga" {
  source  = "Young-ook/spinnaker/aws//modules/frigga"
  version = "2.3.5"
  name    = var.name == null || var.name == "" ? "logs" : var.name
  petname = var.name == null || var.name == "" ? true : false
}

locals {
  namespace      = lookup(local.log_group, "namespace", null)
  name           = module.frigga.name
  log_group_name = local.namespace == null ? local.name : join("/", [local.namespace, local.name])
  default-tags = merge(
    { "terraform.io" = "managed" },
    { "Name" = local.name },
  )
}
