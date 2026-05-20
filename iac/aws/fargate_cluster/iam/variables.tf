variable "app_name" {
  description = "Application name used for resource naming and SSM parameter path scoping."
  type        = string
  default     = "Chat-WSS"
}

variable "aws_region" {
  description = "AWS region where resources are deployed."
  type        = string
  default     = "us-east-2"
}

variable "aws_account_id" {
  description = "AWS account ID used for scoping IAM policy ARNs."
  type        = string
  default     = "156041414531"
}

variable "tags" {
  description = "Tags to apply to all IAM resources."
  type        = map(string)
  default = {
    Owner = "Prabhmeet"
  }
}
