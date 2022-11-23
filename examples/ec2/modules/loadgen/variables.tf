### network
variable "subnets" {
  description = "A list of subnets"
  type        = list(any)
}

variable "security_groups" {
  description = "A list of security groups"
  type        = list(any)
}

### testing
variable "target" {
  description = "An URL to target service"
  type        = string
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
