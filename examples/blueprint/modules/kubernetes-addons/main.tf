### aws partitions
module "aws" {
  source = "Young-ook/spinnaker/aws//modules/aws-partitions"
}

### security/policy
resource "aws_iam_policy" "lbc" {
  name        = "aws-loadbalancer-controller"
  tags        = merge({ "terraform.io" = "managed" }, var.tags)
  description = format("Allow aws-load-balancer-controller to manage AWS resources")
  policy      = file("${path.module}/policy.aws-loadbalancer-controller.json")
}

resource "aws_iam_policy" "kpt" {
  name        = "karpenter"
  tags        = merge({ "terraform.io" = "managed" }, var.tags)
  description = format("Allow karpenter to manage AWS resources")
  policy      = file("${path.module}/policy.karpenter.json")
}

### helm-addons
module "ctl" {
  source  = "Young-ook/eks/aws//modules/helm-addons"
  version = "2.0.6"
  tags    = var.tags
  addons = [
    {
      ### You can disable the mutator webhook feature by setting the helm chart value enableServiceMutatorWebhook to false.
      ### https://github.com/kubernetes-sigs/aws-load-balancer-controller/releases/tag/v2.5.1
      repository     = "https://aws.github.io/eks-charts"
      name           = "aws-load-balancer-controller"
      chart_name     = "aws-load-balancer-controller"
      chart_version  = "1.5.2"
      namespace      = "kube-system"
      serviceaccount = "aws-load-balancer-controller"
      values = {
        "clusterName"                 = var.eks.cluster.name
        "enableServiceMutatorWebhook" = "false"
      }
      oidc        = var.eks.oidc
      policy_arns = [aws_iam_policy.lbc.arn]
    },
    {
      repository     = "https://aws.github.io/eks-charts"
      name           = "aws-cloudwatch-metrics"
      chart_name     = "aws-cloudwatch-metrics"
      namespace      = "kube-system"
      serviceaccount = "aws-cloudwatch-metrics"
      values = {
        "clusterName" = var.eks.cluster.name
      }
      oidc        = var.eks.oidc
      policy_arns = ["arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"]
    },
    {
      repository     = "https://aws.github.io/eks-charts"
      name           = "aws-for-fluent-bit"
      chart_name     = "aws-for-fluent-bit"
      namespace      = "kube-system"
      serviceaccount = "aws-for-fluent-bit"
      values = {
        "cloudWatch.enabled"      = true
        "cloudWatch.region"       = module.aws.region.id
        "cloudWatch.logGroupName" = format("/aws/containerinsights/%s/application", var.eks.cluster.name)
        "firehose.enabled"        = false
        "kinesis.enabled"         = false
        "elasticsearch.enabled"   = false
      }
      oidc        = var.eks.oidc
      policy_arns = ["arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"]
    },
    {
      ### If you are getting a 403 forbidden error, try 'docker logout public.ecr.aws'
      ### https://karpenter.sh/preview/troubleshooting/#helm-error-when-pulling-the-chart
      repository     = null
      name           = "karpenter"
      chart_name     = "oci://public.ecr.aws/karpenter/karpenter"
      chart_version  = "v0.27.1"
      namespace      = "karpenter"
      serviceaccount = "karpenter"
      values = {
        "settings.aws.clusterName"            = var.eks.cluster.name
        "settings.aws.clusterEndpoint"        = var.eks.cluster.control_plane.endpoint
        "settings.aws.defaultInstanceProfile" = var.eks.instance_profile.node_groups == null ? var.eks.instance_profile.managed_node_groups.arn : var.eks.instance_profile.node_groups.arn
      }
      oidc        = var.eks.oidc
      policy_arns = [aws_iam_policy.kpt.arn]
    },
    {
      repository     = "${path.module}/charts/"
      name           = "aws-fis-controller"
      chart_name     = "aws-fis-controller"
      namespace      = "sockshop"
      serviceaccount = "aws-fis-controller"
    },
    {
      repository     = "https://kubernetes-sigs.github.io/metrics-server/"
      name           = "metrics-server"
      chart_name     = "metrics-server"
      namespace      = "kube-system"
      serviceaccount = "metrics-server"
      values = {
        "args[0]" = "--kubelet-preferred-address-types=InternalIP"
      }
    },
  ]
}
