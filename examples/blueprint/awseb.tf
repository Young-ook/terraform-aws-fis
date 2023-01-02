### application/package
data "archive_file" "lambda_zip_file" {
  output_path = join("/", [path.module, "apps/trigger", "lambda_handler.zip"])
  source_dir  = join("/", [path.module, "apps/trigger"])
  excludes    = ["__init__.py", "*.pyc"]
  type        = "zip"
}

### choreography/eventbus
module "cron" {
  depends_on = [data.archive_file.lambda_zip_file]
  source     = "Young-ook/eventbridge/aws//modules/aws-events"
  version    = "0.0.8"
  name       = join("-", [var.name, "cron"])
  tags       = var.tags
  rules = [
    {
      name                = "scheduled_job"
      schedule_expression = "rate(12 hours)"
    },
  ]
  lambda = {
    package = join("/", [path.module, "apps/trigger", "lambda_handler.zip"])
    handler = "lambda_handler.lambda_handler"
    environment_variables = {
      EXPERIMENT_ID = ""
    }
  }
}
