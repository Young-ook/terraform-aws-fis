### default variables

locals {
  default_app = {
    name      = "appcommon"
    type      = "AWS::ResilienceHub::AppCommonAppComponent"
    resources = []
  }
  default_policy = {
    tier = "MissionCritical"
    rto  = 600
    rpo  = 600
  }
}
