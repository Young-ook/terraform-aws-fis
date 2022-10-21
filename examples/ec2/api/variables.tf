### network
variable "vpc" {
  description = "VPC Id"
  type        = string
}

variable "cidr" {
  description = "VPC CIDR"
  type        = string
}

variable "subnets" {
  description = "A list of subnets"
  type        = list(any)
}

variable "az" {
  description = "An index of randomly selected availability zone for single-az deployment"
  type        = number
  default     = -1
}

### description
variable "name" {
  description = "The logical name"
  type        = string
  default     = null
}

### tags
variable "tags" {
  description = "The key-value maps for tagging"
  type        = map(string)
  default     = {}
}
