resource "random_string" "uid" {
  length  = 12
  upper   = false
  lower   = true
  number  = false
  special = false
}

locals {
  service = "fis"
  uid     = join("-", [local.service, random_string.uid.result])
  name    = var.name == null || var.name == "" ? local.uid : var.name
  default-tags = merge(
    { "terraform.io" = "managed" },
    { "Name" = local.name },
  )
}
