terraform {
  required_providers {
    test = {
      source = "terraform.io/builtin/test"
    }
  }
}

module "main" {
  source = "../../"
  for_each = { for log in [
    {
      type = "tc1"
      log_group = {
        retension_days = 3
      }
      log_metric_filters = [
        {
          pattern   = "ERROR"
          name      = "ErrorCount"
          namespace = "MyApp"
        },
      ]
    },
    {
      type      = "tc2"
      log_group = null
      log_metric_filters = null
    },
    {
      type = "tc3"
      log_group = {
        namespace      = "/aws/lambda"
        retension_days = 5
      }
      log_metric_filters = null
    },
  ] : log.type => log }
  name               = join("-", ["logs", each.key])
  log_group          = lookup(each.value, "log_group")
  log_metric_filters = lookup(each.value, "log_metric_filters")
}
