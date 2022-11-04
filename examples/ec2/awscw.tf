### application/logs
module "logs" {
  source  = "Young-ook/lambda/aws//modules/logs"
  version = "0.2.6"
  for_each = { for l in [
    {
      type = "fis"
      log_group = {
        namespace      = "/aws/fis"
        retension_days = 3
      }
    },
  ] : l.type => l }
  log_group = each.value.log_group
}
