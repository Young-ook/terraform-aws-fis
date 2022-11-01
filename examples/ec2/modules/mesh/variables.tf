### network
variable "aws_region" {
  description = "The aws region"
  type        = string
}

### application
variable "app" {
  description = "The information of microservice API applications"
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
