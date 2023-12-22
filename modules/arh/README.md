# AWS Resilience Hub
[AWS Resilience Hub](https://aws.amazon.com/resilience-hub/) provides a central place to define, validate, and track the resilience of your applications on AWS. This module creates an AWS Resilience Hub application to define the recovery objectives and monitor the status of availablity of your application.

## Setup
### Prerequisites
This module requires *terraform*. If you don't have the terraform tool in your environment, go to the main [page](https://github.com/Young-ook/terraform-aws-fis) of this repository and follow the installation instructions.

### Quickstart
Move to the your local workspace and prepare load testing configuration files. This is an example files to create an AWS Resilience Hub application.

```
module "resilient-app" {
  source  = "Young-ook/fis/aws//modules/arh"
}
```
Run terraform:
```
terraform init
terraform apply
```
