# Variables for providing to module fixture codes

### network
variable "aws_region" {
  description = "The aws region"
  type        = string
}

variable "azs" {
  description = "A list of availability zones"
  type        = list(string)
}

variable "use_default_vpc" {
  description = "A feature flag for whether to use default vpc"
  type        = bool
}

variable "cidr" {
  description = "The vpc CIDR (e.g. 10.0.0.0/16)"
  type        = string
}

### kubernetes cluster
variable "kubernetes_version" {
  description = "The target version of kubernetes"
  type        = string
}

variable "managed_node_groups" {
  description = "Amazon managed node groups definition"
  default     = []
}

variable "fargate_profiles" {
  description = "Amazon Fargate profiles"
  default     = []
}

### description
variable "name" {
  description = "The logical name of the module instance"
  type        = string
  default     = null
}

### tags
variable "tags" {
  description = "The key-value maps for tagging"
  type        = map(string)
  default     = {}
}
