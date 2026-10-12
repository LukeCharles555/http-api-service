variable "environment" {
  type = string
}

variable "service_name" {
  type    = string
  default = "infra-demo-api"
}

variable "bundle_path" {
  description = "Absolute path to the built handler.cjs file."
  type        = string
}

variable "memory_size" {
  type    = number
  default = 128
}

variable "timeout" {
  type    = number
  default = 5
}

variable "log_retention_days" {
  type    = number
  default = 7
}

variable "log_level" {
  type    = string
  default = "info"
}

variable "api_rate_limit" {
  description = "Target sustained requests per second."
  type        = number
  default     = 1
}

variable "api_burst_limit" {
  description = "Allowed request burst."
  type        = number
  default     = 2
}