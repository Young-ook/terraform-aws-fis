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
  version    = "0.0.9"
  name       = join("-", [var.name, "cron"])
  tags       = var.tags
  rules = [
    {
      name                = "scheduled_job"
      schedule_expression = "rate(12 hours)"
    },
  ]
  lambda = {
    function = {
      package = join("/", [path.module, "apps/trigger", "lambda_handler.zip"])
      handler = "lambda_handler.lambda_handler"
      environment_variables = {
        EXPERIMENT_ID = ""
      }
    }
    policy = [aws_iam_policy.fis-start.arn]
  }
}

resource "aws_iam_policy" "fis-start" {
  name        = "lambda-fis-start-experiment"
  tags        = merge({ "terraform.io" = "managed" }, var.tags)
  description = format("Allow lambda function to start a fault injection experiment")
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow",
        Action = "fis:StartExperiment"
        Resource = [
          "arn:aws:fis:*:*:experiment-template/*",
          "arn:aws:fis:*:*:experiment/*"
        ]
      }
    ]
  })
}
