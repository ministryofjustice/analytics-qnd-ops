variable "region" {
  default = "eu-west-1"
}

variable "kops_bucket_name" {}
variable "terraform_bucket_name" {}
variable "xyz_root_domain" {}
variable "es_domain" {}
variable "es_port" {}
variable "es_username" {}
variable "es_password" {}

variable "es_scheme" {
  default = "https"
}

variable "uploads_bucket_name" {
  default = "mojap-land"
}

variable "global_cloudtrail_bucket_name" {
  default = "moj-analytics-global-cloudtrail"
}

variable "s3_logs_bucket_name" {
  default = "moj-analytics-s3-logs"
}
