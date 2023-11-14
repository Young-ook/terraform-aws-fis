### monitoring
variable "application" {
  description = "The definition of target application for resiliency monitoring"
  type        = any
  default     = {}
}

variable "policy" {
  description = "The application resiliency policy configuration (RTO/RPO)"
  type        = any
  default     = {}
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
