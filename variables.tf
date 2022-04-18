### experiments
variable "experiments" {
  description = "List of fault injection simulator experiment templates."
  type        = list(any)
  validation {
    condition     = var.experiments != null && length(var.experiments) > 0
    error_message = "Experiment template list must not be null. also, the length of list should be greater than 0."
  }
}

### description
variable "name" {
  description = "Name of metric alarm. This name must be unique within the AWS account"
  type        = string
  default     = ""
}

### tags
variable "tags" {
  description = "The key-value maps for tagging"
  type        = map(string)
  default     = {}
}
