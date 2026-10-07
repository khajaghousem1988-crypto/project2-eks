variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "banking-eks"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"
}

variable "project1_state_bucket" {
  description = "S3 bucket containing Project 1 Terraform state"
  type        = string
  default     = "banking-infra-dev"
}

variable "project1_state_key" {
  description = "Project 1 Terraform state key"
  type        = string
  default     = "terraform.tfstate"
}
