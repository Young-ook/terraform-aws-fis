### application/logs
module "logs" {
  source  = "Young-ook/eventbridge/aws//modules/logs"
  version = "0.0.6"
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
