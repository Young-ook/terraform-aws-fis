# Taurus by BlazeMeter
[Taurus](https://gettaurus.org/) is a integrated load testing tool that hides the complexity of performance and functional tests with an automation-friendly convenience wrapper. Taurus relies on JMeter, Gatling, Locust.io, and Selenium WebDriver as its underlying tools.

## Getting started
This module requires terraform tool version 0.13 or higher and AWS CLI. If you don't have thoes tools on your workspace, please follow the [Getting started](https://github.com/Young-ook/terraform-aws-fis#getting-started).

### Setup
```
module "bzt" {
  source  = "Young-ook/fis/aws//modules/bzt"
}
```
Run terraform:
```
terraform init
terraform apply
```

### Connect
Move to the EC2 service page on the AWS Management Conosol and select Instances button on the left side menu. Find an instance that you launched. Select the instance and click *Connect* button on top of the window. After then you will see three tabs EC2 Instance Connect, Session Manager, SSH client. Select Session Manager tab and follow the instruction on the screen.

### Run Taurus
You can use `-h` option to display help message when you run `bzt` command.
```
bzt -h
Usage: bzt [options] [configs] [-aliases]

BlazeMeter Taurus Tool v1.16.18, the configuration-driven test running engine

Options:
  -h, --help            show this help message and exit
  -l LOG, --log=LOG     Log file location
  -o OPTION, --option=OPTION
                        Override option in config
  -q, --quiet           Only errors and warnings printed to console
  -v, --verbose         Prints all logging messages to console
  -n, --no-system-configs
                        Skip system and user config files
```

![aws-ssm-bzt-dashboard](../../images/aws-ssm-bzt-dashboard.png)
![aws-ssm-bzt-log](../../images/aws-ssm-bzt-log.png)
