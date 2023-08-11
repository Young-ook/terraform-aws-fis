### fault injection simulator experiment templates

module "random-az" {
  source = "../../modules/roulette"
  items  = var.azs
}

module "awsfis" {
  source  = "Young-ook/fis/aws"
  version = "2.0.0"
  name    = var.name
  tags    = var.tags
  experiments = [
    {
      name        = "az-outage"
      tags        = var.tags
      description = "Simulate an AZ outage"
      actions = {
        az-outage = {
          description = "Block all EC2 traffics from and to the subnets"
          action_id   = "aws:network:disrupt-connectivity"
          targets     = { Subnets = module.random-az.item }
          parameters = {
            duration = "PT5M"
            scope    = "availability-zone"
          }
        }
        ec2-blackhole = {
          description = "Drop all network packets from and to EC2 instances"
          action_id   = "aws:ssm:send-command"
          targets     = { Instances = "ec2-instances" }
          parameters = {
            duration           = "PT5M"
            documentArn        = data.aws_ssm_document.network-blackhole.arn
            documentParameters = "{\"DurationSeconds\":\"300\",\"LossPercent\":\"100\",\"InstallDependencies\":\"True\"}"
          }
        }
        failover-rds = {
          description = "Failover Aurora cluster"
          action_id   = "aws:rds:failover-db-cluster"
          targets     = { Clusters = "rds-cluster" }
        }
      }
      targets = {
        var.azs[module.random-az.index] = {
          resource_type = "aws:ec2:subnet"
          parameters = {
            availabilityZoneIdentifier = module.random-az.item
            vpc                        = module.vpc.vpc.id
          }
          selection_mode = "ALL"
        }
        ec2-instances = {
          resource_type  = "aws:ec2:instance"
          resource_tags  = { example = "fis_blueprint" }
          selection_mode = "ALL"
          filters = [
            {
              path   = "Placement.AvailabilityZone"
              values = [module.random-az.item]
            },
            {
              path   = "State.Name"
              values = ["running"]
            }
          ],
        }
        rds-cluster = {
          resource_type  = "aws:rds:cluster"
          resource_tags  = { example = "fis_blueprint" }
          selection_mode = "ALL"
          filters = [
            {
              path   = "Placement.AvailabilityZone"
              values = [module.random-az.item]
            },
          ],
        }
      }
      stop_conditions = [
        {
          source = "aws:cloudwatch:alarm",
          value  = module.alarm["eks-cpu"].alarm.arn
        },
        {
          source = "aws:cloudwatch:alarm",
          value  = module.alarm["rds-cpu"].alarm.arn
        }
      ]
      log_configuration = {
        log_schema_version = 1
        cloudwatch_logs_configuration = {
          log_group_arn = format("%s:*", module.logs["fis"].log_group.arn)
        }
      }
    },
    {
      name        = "eks-stress"
      tags        = var.tags
      description = "Simulate stress on kubernetes resources",
      actions = {
        eks-pod-cpu = {
          action_id = "aws:eks:inject-kubernetes-custom-resource",
          parameters = {
            maxDuration          = "PT5M"
            kubernetesApiVersion = "chaos-mesh.org/v1alpha1"
            kubernetesKind       = "StressChaos"
            kubernetesNamespace  = "chaos-mesh"
            kubernetesSpec : "{\"mode\": \"all\",\"selector\": {\"labelSelectors\": {\"name\": \"carts\"}},\"stressors\": {\"cpu\": {\"workers\": 1,\"load\": 60}},\"duration\":\"1m\"}"
          }
          targets = { Cluster = "eks-cluster" }
        }
        eks-pod-kill = {
          action_id = "aws:eks:inject-kubernetes-custom-resource"
          parameters = {
            maxDuration          = "PT5M"
            kubernetesApiVersion = "chaos-mesh.org/v1alpha1"
            kubernetesKind       = "PodChaos"
            kubernetesNamespace  = "chaos-mesh"
            kubernetesSpec       = "{\"selector\":{\"namespaces\":[\"sockshop\"],\"labelSelectors\":{\"name\":\"carts\"}},\"mode\":\"one\",\"action\": \"pod-kill\",\"gracePeriod\":0}"
          }
          targets : { Cluster = "eks-cluster" }
        }
        eks-pod-mem = {
          action_id = "aws:eks:inject-kubernetes-custom-resource"
          parameters = {
            maxDuration          = "PT5M"
            kubernetesApiVersion = "chaos-mesh.org/v1alpha1"
            kubernetesKind       = "StressChaos"
            kubernetesNamespace  = "chaos-mesh"
            kubernetesSpec       = "{\"mode\": \"one\",\"selector\": {\"labelSelectors\": {\"name\": \"carts\"}},\"stressors\": {\"memory\": {\"workers\": 4,\"size\": \"256MB\"}}}"
          }
          targets = { Cluster = "eks-cluster" }
        }
        eks-node-kill = {
          action_id = "aws:eks:terminate-nodegroup-instances"
          parameters = {
            instanceTerminationPercentage = "20"
          }
          targets = { Nodegroups = "eks-nodes" }
        }
      }
      targets = {
        eks-cluster = {
          resource_type  = "aws:eks:cluster"
          resource_arns  = [module.eks.cluster["control_plane"].arn]
          selection_mode = "PERCENT(40)"
        }
        eks-nodes = {
          resource_type  = "aws:eks:nodegroup"
          resource_arns  = [module.eks.cluster.data_plane.managed_node_groups.apps.arn]
          selection_mode = "ALL"
        }
      }
      stop_conditions = [
        {
          source = "aws:cloudwatch:alarm",
          value  = module.alarm["eks-cpu"].alarm.arn
        },
        {
          source = "aws:cloudwatch:alarm",
          value  = module.alarm["svc-health"].alarm.arn
        }
      ]
      log_configuration = {
        log_schema_version = 1
        cloudwatch_logs_configuration = {
          log_group_arn = format("%s:*", module.logs["fis"].log_group.arn)
        }
      }
    },
    {
      name        = "net-delay"
      description = "Simulate network delay"
      actions = {
        eks-pod-net-delay = {
          action_id = "aws:eks:inject-kubernetes-custom-resource"
          parameters = {
            maxDuration          = "PT5M"
            kubernetesApiVersion = "chaos-mesh.org/v1alpha1"
            kubernetesKind       = "NetworkChaos"
            kubernetesNamespace  = "chaos-mesh"
            kubernetesSpec       = "{\"mode\": \"one\",\"selector\": {\"labelSelectors\": {\"name\": \"carts\"}},\"action\":\"delay\",\"delay\": {\"latency\":\"10ms\"},\"duration\":\"40s\"}"
          }
          targets = { Cluster = "eks-cluster" }
        }
        ec2-net-delay = {
          action_id = "aws:ssm:send-command"
          parameters = {
            duration           = "PT5M"
            documentArn        = format("arn:aws:ssm:%s::document/AWSFIS-Run-Network-Latency", var.aws_region)
            documentParameters = "{\"DurationSeconds\": \"300\", \"InstallDependencies\": \"True\", \"DelayMilliseconds\": \"100\"}"
          }
          targets = { Instances = "ec2-instances" }
        }
      }
      targets = {
        eks-cluster = {
          resource_type  = "aws:eks:cluster"
          resource_arns  = [module.eks.cluster["control_plane"].arn]
          selection_mode = "ALL"
        }
        ec2-instances = {
          resource_type = "aws:ec2:instance"
          resource_tags = { env = "prod" }
          filters = [
            {
              path   = "State.Name"
              values = ["running"]
            },
          ]
          selection_mode = "ALL"
        }
      }
      stop_conditions = [
        {
          source = "aws:cloudwatch:alarm",
          value  = module.alarm["svc-health"].alarm.arn
        },
      ]
      log_configuration = {
        log_schema_version = 1
        cloudwatch_logs_configuration = {
          log_group_arn = format("%s:*", module.logs["fis"].log_group.arn)
        }
      }
    },
    {
      name        = "ec2-stress"
      description = "Simulate stress on ec2 instances"
      actions = {
        DiskFull = {
          action_id = "aws:ssm:send-command"
          targets   = { Instances = "ec2-instances" }
          parameters = {
            duration           = "PT5M"
            documentArn        = module.awsfis.documents["FIS-Run-Disk-Stress"].arn
            documentParameters = "{\"DurationSeconds\": \"300\", \"Workers\": \"4\", \"Percent\": \"70\", \"InstallDependencies\": \"True\"}"
          }
        }
        ec2-spot-interruption = {
          description = "Interrupt ec2 spot instance"
          action_id   = "aws:ec2:send-spot-instance-interruptions"
          parameters = {
            durationBeforeInterruption = "PT2M"
          }
          targets = { SpotInstances = "spot-instances" }
        }
      }
      targets = {
        ec2-instances = {
          resource_type  = "aws:ec2:instance"
          resource_tags  = { release = "canary" }
          selection_mode = "PERCENT(70)"
        }
        spot-instances = {
          resource_type = "aws:ec2:spot-instance"
          resource_tags = { "chaos" = "ready" }
          filters = [
            {
              path   = "State.Name"
              values = ["running"]
            }
          ],
          selection_mode = "COUNT(1)"
        }
      }
      stop_conditions = [
        {
          source = "aws:cloudwatch:alarm",
          value  = module.alarm["eks-disk"].alarm.arn
        },
        {
          source = "aws:cloudwatch:alarm",
          value  = module.alarm["eks-cpu"].alarm.arn
        }
      ]
      log_configuration = {
        log_schema_version = 1
        cloudwatch_logs_configuration = {
          log_group_arn = format("%s:*", module.logs["fis"].log_group.arn)
        }
      }
    },
    {
      name        = "ec2-api-error"
      description = "Simulate AWS API error"
      actions = {
        aws-api-throttle = {
          action_id = "aws:fis:inject-api-throttle-error"
          targets   = { Roles = "ec2-instances" }
          parameters = {
            service    = "ec2"
            operations = "DescribeInstances,DescribeVolumes"
            percentage = "90"
            duration   = "PT2M"
          }
        }
        aws-api-internal-error = {
          action_id   = "aws:fis:inject-api-internal-error"
          description = "AWS API internal error"
          targets     = { Roles = "ec2-instances" }
          parameters = {
            service    = "ec2"
            operations = "AllocateAddress,AssignPrivateIpAddresses,DescribeVolumes"
            percentage = "100"
            duration   = "PT2M"
          }
        }
        aws-api-unavailable-error = {
          action_id = "aws:fis:inject-api-unavailable-error"
          targets   = { Roles = "ec2-instances" }
          parameters = {
            service    = "ec2"
            operations = "AssignPrivateIpAddresses,DescribeInstances,DescribeVolumes"
            percentage = "100"
            duration   = "PT2M"
          }
        }
      }
      targets = {
        ec2-instances = {
          resource_type  = "aws:iam:role"
          resource_arns  = [module.ec2["a"].role.canary.arn]
          selection_mode = "ALL"
        }
      }
      stop_conditions = [
        {
          source = "aws:cloudwatch:alarm",
          value  = module.ec2["a"].alarms.cpu.arn
        }
      ]
      log_configuration = {
        log_schema_version = 1
        cloudwatch_logs_configuration = {
          log_group_arn = format("%s:*", module.logs["fis"].log_group.arn)
        }
      }
    },
    {
      name        = "rds-stress"
      description = "Simulate stress on RDS clusters and instances"
      actions = {
        reboot-rds = {
          action_id  = "aws:rds:reboot-db-instances"
          parameters = { forceFailover = "false" }
          targets    = { DBInstances = "rds-instances" }
        }
        failover-rds = {
          description = "Failover Aurora cluster"
          action_id   = "aws:rds:failover-db-cluster"
          targets     = { Clusters = "rds-cluster" }
        }
      }
      targets = {
        rds-instances = {
          resource_type  = "aws:rds:db"
          resource_arns  = [module.rds.instances.0.arn]
          selection_mode = "ALL"
        }
        rds-cluster = {
          resource_type  = "aws:rds:cluster"
          resource_arns  = [module.rds.cluster.arn]
          selection_mode = "ALL"
        }
      }
      stop_conditions = [
        {
          source = "aws:cloudwatch:alarm",
          value  = module.alarm["rds-cpu"].alarm.arn
        }
      ]
      log_configuration = {
        log_schema_version = 1
        cloudwatch_logs_configuration = {
          log_group_arn = format("%s:*", module.logs["fis"].log_group.arn)
        }
      }
    },
  ]
}

data "aws_ssm_document" "network-blackhole" {
  name            = "AWSFIS-Run-Network-Packet-Loss"
  document_format = "YAML"
}
