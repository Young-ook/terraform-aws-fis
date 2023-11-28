### fault injection simulator experiment templates

module "random-az" {
  source = "../../modules/roulette"
  items  = var.azs
}

data "aws_ssm_document" "network-blackhole" {
  name            = "AWSFIS-Run-Network-Packet-Loss"
  document_format = "YAML"
}

### experiments
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
        log_schema_version = 2
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
          action_id = "aws:eks:pod-cpu-stress",
          parameters = {
            duration                 = "PT5M"
            percent                  = "80"
            workers                  = "1"
            kubernetesServiceAccount = "aws-fis-controller"
          }
          targets = { Pods = "eks-pods" }
        }
        eks-pod-kill = {
          action_id = "aws:eks:pod-delete"
          parameters = {
            gracePeriodSeconds       = "0"
            kubernetesServiceAccount = "aws-fis-controller"
          }
          start_after = ["eks-pod-cpu", "eks-pod-mem"]
          targets : { Pods = "eks-pods" }
        }
        eks-pod-mem = {
          action_id = "aws:eks:pod-memory-stress"
          parameters = {
            duration                 = "PT5M"
            percent                  = "80"
            workers                  = "1"
            kubernetesServiceAccount = "aws-fis-controller"
          }
          targets = { Pods = "eks-pods" }
        }
        eks-node-kill = {
          action_id = "aws:eks:terminate-nodegroup-instances"
          parameters = {
            instanceTerminationPercentage = "20"
          }
          start_after = ["eks-pod-kill"]
          targets     = { Nodegroups = "eks-nodes" }
        }
      }
      targets = {
        eks-pods = {
          resource_type = "aws:eks:pod"
          parameters = {
            clusterIdentifier = module.eks.cluster.name
            namespace         = "sockshop"
            selectorType      = "labelSelector"
            selectorValue     = "name=carts-db"
          }
          selection_mode = "PERCENT(50)"
        }
        eks-nodes = {
          resource_type  = "aws:eks:nodegroup"
          resource_arns  = [module.eks.cluster.data_plane.managed_node_groups.apps.arn]
          selection_mode = "COUNT(1)"
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
        log_schema_version = 2
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
        log_schema_version = 2
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
        log_schema_version = 2
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
        log_schema_version = 2
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
      }
      targets = {
        rds-instances = {
          resource_type  = "aws:rds:db"
          resource_arns  = [module.rds.instances.0.arn]
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
        log_schema_version = 2
        cloudwatch_logs_configuration = {
          log_group_arn = format("%s:*", module.logs["fis"].log_group.arn)
        }
      }
    },
  ]
}

# Need to update aws-auth configmap with,
#
#    - rolearn: arn:aws:iam::{AWS_ACCOUNT_ID}:role/{AWS_IAM_ROLE_FOR_AWS_FIS}
#      username: fis-experiment
#
# for more details, https://docs.aws.amazon.com/fis/latest/userguide/eks-pod-actions.html
#
# `eksctl` provides a command to update the aws-auth ConfigMap to bind the Kubernetes RBAC with AWS IAM.
#

resource "local_file" "eksctl" {
  depends_on = [module.eks, module.kubernetes-addons]
  content = yamlencode({
    apiVersion = "eksctl.io/v1alpha5"
    kind       = "ClusterConfig"
    metadata = {
      name   = module.eks.cluster.name
      region = var.aws_region
    }
    iamIdentityMappings = [
      {
        arn             = module.awsfis.role["fis"].arn
        username        = "fis-experiment"
        noDuplicateARNs = true
      },
    ]
  })
  filename        = join("/", [path.module, "eksctl-config.yaml"])
  file_permission = "0600"
}

resource "null_resource" "eksctl" {
  depends_on = [local_file.eksctl]
  provisioner "local-exec" {
    command = "eksctl create iamidentitymapping -f ${path.module}/eksctl-config.yaml"
  }
}

### application/alarm
module "alarm" {
  source  = "Young-ook/eventbridge/aws//modules/alarm"
  version = "0.0.13"
  for_each = { for a in [
    {
      name        = "rds-cpu"
      description = "This metric monitors rds cpu utilization"
      alarm_metric = {
        comparison_operator = "GreaterThanOrEqualToThreshold"
        evaluation_periods  = 1
        datapoints_to_alarm = 1
        threshold           = 60
      }
      metric_query = [
        {
          id          = "rds_cpu_high"
          return_data = true
          metric = [
            {
              metric_name = "CPUUtilization"
              namespace   = "AWS/RDS"
              stat        = "Average"
              period      = 60
              dimensions  = { DBClusterIdentifier = module.rds.cluster.id }
            },
          ]
        },
      ]
    },
    {
      name        = "eks-cpu"
      description = "This metric monitors eks node cpu utilization"
      alarm_metric = {
        comparison_operator = "GreaterThanOrEqualToThreshold"
        evaluation_periods  = 1
        datapoints_to_alarm = 1
        threshold           = 60
      }
      metric_query = [
        {
          id          = "eks_cpu_high"
          return_data = true
          metric = [
            {
              metric_name = "node_cpu_utilization"
              namespace   = "ContainerInsights"
              stat        = "Average"
              period      = 30
              dimensions  = { ClusterName = module.eks.cluster.name }
            },
          ]
        },
      ]
    },
    {
      name        = "eks-disk"
      description = "This metric monitors ec2 disk filesystem usage"
      alarm_metric = {
        comparison_operator = "GreaterThanOrEqualToThreshold"
        extended_statistic  = "p90"
        evaluation_periods  = 1
        datapoints_to_alarm = 1
        period              = 30
        threshold           = 60
        metric_name         = "node_filesystem_utilization"
        namespace           = "ContainerInsights"
        dimensions          = { ClusterName = module.eks.cluster.name }
      }
    },
    {
      name        = "svc-health"
      description = "This metric monitors healty backed pods of a service"
      alarm_metric = {
        comparison_operator = "LessThanThreshold"
        evaluation_periods  = 1
        datapoints_to_alarm = 1
        threshold           = 1
      }
      metric_query = [
        {
          id          = "runnung_pods"
          return_data = true
          metric = [
            {
              metric_name = "service_number_of_running_pods"
              namespace   = "ContainerInsights"
              stat        = "Average"
              period      = 30
              dimensions = {
                Namespace   = "sockshop"
                Service     = "front-end"
                ClusterName = module.eks.cluster.name
              }
            },
          ]
        },
      ]
    },
  ] : a.name => a }
  name         = join("-", [each.key, "alarm"])
  tags         = merge(local.default-tags, var.tags)
  description  = each.value.description
  alarm_metric = each.value.alarm_metric
  metric_query = try(each.value.metric_query, null)
}

### application/logs
module "logs" {
  source  = "Young-ook/eventbridge/aws//modules/logs"
  version = "0.0.6"
  for_each = { for l in [
    {
      type = "codebuild"
      log_group = {
        namespace      = "/aws/codebuild"
        retension_days = 5
      }
    },
    {
      type = "fis"
      log_group = {
        namespace      = "/aws/fis"
        retension_days = 3
      }
    },
    {
      type = "redis"
      log_group = {
        namespace      = "/aws/elasticache"
        retension_days = 3
      }
    },
  ] : l.type => l }
  name      = join("-", [var.name, each.key])
  log_group = each.value.log_group
}
