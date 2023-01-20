### application/loadgen
module "loadgen" {
  depends_on      = [module.ec2]
  source          = "Young-ook/fis/aws//modules/bzt"
  version         = "1.0.3"
  name            = join("-", [var.name, "loadgen"])
  tags            = merge(var.tags, local.default-tags)
  subnets         = values(module.vpc.subnets["public"])
  security_groups = [module.ec2["a"].security_group.id, module.ec2["b"].security_group.id]
  config          = templatefile("${path.module}/bzt.test.yaml", { target = format("http://%s", module.ec2["a"].load_balancer) })
  task            = templatefile("${path.module}/bzt.test.py", {})
}
