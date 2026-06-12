variable "github_org" {
  description = "GitHub org or username that owns the repo"
  type        = string
}

variable "github_repo" {
  description = "Repository name, e.g. bodytechsolutions.com"
  type        = string
  default     = "bodytechsolutions.com"
}

variable "aws_account_id" {
  description = "AWS account ID this role lives in"
  type        = string
  sensitive   = true
}

variable "environment" {
  description = "Deployment environment (development or production)"
  type        = string
}