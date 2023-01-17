locals {
  namespace = "corp.internal"
  default-tags = merge(
    { "terraform.io" = "managed" },
    { "Name" = var.name },
  )
}

