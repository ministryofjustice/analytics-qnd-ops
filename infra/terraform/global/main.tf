terraform {
  backend "s3" {
    bucket = "terraform.analytics.justice.gov.uk"
    key    = "base/terraform.tfstate"
    region = "eu-west-1"
  }
}

provider "aws" {
  region  = "${var.region}"
  version = "~> 1.15"
}

data "aws_caller_identity" "current" {}

module "aws_account_logging" {
  source = "../modules/aws_account_logging"

  es_domain   = "${var.es_domain}"
  es_port     = "${var.es_port}"
  es_scheme   = "${var.es_scheme}"
  es_username = "${var.es_username}"
  es_password = "${var.es_password}"

  cloudtrail_s3_bucket_arn = "${aws_s3_bucket.global_cloudtrail.arn}"
  cloudtrail_s3_bucket_id  = "${aws_s3_bucket.global_cloudtrail.id}"

  account_id = "${data.aws_caller_identity.current.account_id}"
}

module "log_pruning" {
  source = "../modules/log_pruning"

  curator_conf = <<EOF
- name: main
  endpoint: ${var.es_scheme}://${var.es_username}:${var.es_password}@${var.es_domain}:${var.es_port}
  indices:
    - prefix: s3logs-
      days: 30
    - prefix: cloudtrail-
      days: 30
    - prefix: logstash-dev-
      days: 2
    - prefix: logstash-apps-dev-
      days: 2
    - prefix: logstash-alpha-
      days: 30
    - prefix: logstash-apps-alpha-
      days: 30
EOF
}

module "hmpps_nomis_upload_user" {
  source = "../modules/data_upload_user"

  upload_bucket_arn = "${aws_s3_bucket.uploads.arn}"
  org_name          = "hmpps"
  system_name       = "nomis"
}

module "hmpps_oasys_upload_user" {
  source = "../modules/data_upload_user"

  upload_bucket_arn = "${aws_s3_bucket.uploads.arn}"
  org_name          = "hmpps"
  system_name       = "oasys"
}
