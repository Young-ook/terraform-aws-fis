### template
variable "description" {
  description = "Description of fault injection experiment template"
  type        = string
}

variable "actions" {
  description = "A list of experiment targets"
  type        = any
}

variable "targets" {
  description = "A list of experiment targets"
  type        = any
}

variable "logs" {
  description = "Log group configuration"
  type        = any
  default     = null
}

variable "stop_conditions" {
  description = "A list of stop conditions"
  type        = list(any)
  default     = null
}

variable "role" {
  description = "An IAM Role ARN for fault injection experiment"
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
