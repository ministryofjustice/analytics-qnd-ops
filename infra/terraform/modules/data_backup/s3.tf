resource "aws_s3_bucket" "nfs_backup" {
  bucket = "${var.env}-moj-analytics-nfs-backup"
  region = "${data.aws_region.current.name}"
  acl = "private"

  tags {
    Name = "${var.env}-moj-analytics-nfs-backup"
  }

  versioning {
    enabled = true
  }

  # Current object versions transition to Glacier after 30 days
  # and are deleted after 90 (including deleted object markers)

  # Old versions transition to Glacier after 14 days and are
  # deleted after 30

  lifecycle_rule {
    id = "${var.env}-nfs-backup-transition"
    abort_incomplete_multipart_upload_days = 1
    enabled = true

    transition {
      days = 30
      storage_class = "GLACIER"
    }

    expiration {
      days = 90
      expired_object_delete_marker = true
    }

    noncurrent_version_transition {
      days = 14
      storage_class = "GLACIER"
    }

    noncurrent_version_expiration {
      days = 30
    }
  }
}