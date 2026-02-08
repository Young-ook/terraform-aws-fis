### log
variable "log_group" {
  description = "Log group configuration"
  type        = map(any)
  default     = {}
}

variable "log_metric_filters" {
  description = "Log metric tranform filters"
  type        = list(any)
  default     = []
}

### description
variable "name" {
  description = "Log group name"
  type        = string
  default     = null
}

### tags
variable "tags" {
  description = "The key-value maps for tagging"
  type        = map(string)
  default     = {}
}
