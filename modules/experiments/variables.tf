### template
variable "templates" {
  description = "A list of fault injection experiment templates"
  type        = any
  default     = []
}

### tags
variable "tags" {
  description = "The key-value maps for tagging"
  type        = map(string)
  default     = {}
}
