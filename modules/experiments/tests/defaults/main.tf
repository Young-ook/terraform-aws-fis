terraform {
  required_providers {
    test = {
      source = "terraform.io/builtin/test"
    }
  }
}

module "main" {
  source      = "../.."
  description = "Simulate an AZ outage"
  actions = {
    "AZOutage" = {
      "actionId"    = "aws:network:disrupt-connectivity"
      "description" = "Block all EC2 traffics from and to the subnets"
      "parameters" = {
        "duration" = "PT5M"
        "scope"    = "availability-zone"
      },
      "targets" = {
        "Subnets" = "us-west-2b"
      }
    }
    "FailOverCluster" = {
      "actionId"    = "aws:rds:failover-db-cluster"
      "description" = "Failover Aurora cluster"
      "parameters"  = {}
      "targets" = {
        "Clusters" = "rds-cluster"
      }
    }
  }
  targets = {
    "us-west-2b" = {
      "resourceType" = "aws:ec2:subnet"
      "parameters" = {
        "availabilityZoneIdentifier" = "us-west-2b"
        "vpc"                        = "vpc-123450987"
      }
      "selectionMode" = "ALL"
    }
    "rds-cluster" = {
      "resourceType"  = "aws:rds:cluster"
      "resourceArns"  = ["arn:aws:rds:us-west-2:123412341234:db:i-sirjchsgduyeyrej"]
      "selectionMode" = "ALL"
    }
  }
  stop_conditions = [
    {
      "source" = "aws:cloudwatch:alarm",
      "value"  = "arn:aws:cloudwatch:us-west-2:123412341234:alarm:fis-blueprint-eks-cpu-alarm"
    },
    {
      "source" = "aws:cloudwatch:alarm",
      "value"  = "arn:aws:cloudwatch:us-west-2:123412341234:alarm:fis-blueprint-rds-cpu-alarm"
    }
  ]
  logs = {
    "logSchemaVersion" = 1,
    "cloudWatchLogsConfiguration" = {
      "logGroupArn" : "arn:aws:cloudwatch:us-west-2:123412341234:log:fis-blueprint-log"
    }
  }
  role = "arn:aws:iam:us-west-2:123412341234:role:fis-run"
}

output "json" {
  value = module.main.json
}
