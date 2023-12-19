variable "vpc2_self_link" {
  description = "The self link of the VPC network for the SQL instance"
  type        = string
}

variable "project" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region"
  type        = string
}

