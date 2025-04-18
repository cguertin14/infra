locals {
  bucket_prefix = "velero-backups"
}

data "aws_iam_policy_document" "backup_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }
  }
}

resource "aws_iam_user" "backup_user" {
  name = "${local.bucket_prefix}-user"
}

# WARNING: Go create this in the console and use copy/paste it from there.
# resource "aws_iam_access_key" "backup_access_key" {
#   user     = aws_iam_user.backup_user.name
# }

resource "aws_s3_bucket" "backup_bucket" {
  bucket_prefix = "${local.bucket_prefix}-bucket"
  lifecycle {
    prevent_destroy = true # Must be destroyed in the console.
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "expire_old_backups" {
  bucket = aws_s3_bucket.backup_bucket.id
  rule {
    id     = "expire-old-backups"
    status = "Enabled"
    filter {
      prefix = ".tar.gz"
    }
    expiration {
      days = 14 # expire objects after 2 weeks
    }
  }
}

resource "aws_s3_bucket_policy" "backup_bucket_policy" {
  bucket = aws_s3_bucket.backup_bucket.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_user.backup_user.arn
        }
        Action = [
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:PutObject",
          "s3:PutObjectTagging",
          "s3:AbortMultipartUpload",
          "s3:ListMultipartUploadParts"
        ]
        Resource = [
          "arn:aws:s3:::${aws_s3_bucket.backup_bucket.id}",
          "arn:aws:s3:::${aws_s3_bucket.backup_bucket.id}/*",
        ]
      },
    ]
  })
}

resource "aws_s3_bucket_public_access_block" "backup_bucket_public_access_block" {
  bucket = aws_s3_bucket.backup_bucket.id

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "backup_bucket_versioning" {
  bucket = aws_s3_bucket.backup_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

data "aws_iam_policy_document" "backup_policy" {
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:DeleteObject",
      "s3:PutObject",
      "s3:PutObjectTagging",
      "s3:AbortMultipartUpload",
      "s3:ListMultipartUploadParts"
    ]
    resources = [
      "arn:aws:s3:::${aws_s3_bucket.backup_bucket.id}",
      "arn:aws:s3:::${aws_s3_bucket.backup_bucket.id}/*",
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "ec2:DescribeVolumes",
      "ec2:DescribeSnapshots",
      "ec2:CreateTags",
      "ec2:CreateVolume",
      "ec2:CreateSnapshot",
      "ec2:DeleteSnapshot"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_user_policy" "backup_user_policy" {
  name   = "${local.bucket_prefix}-policy"
  user   = aws_iam_user.backup_user.id
  policy = data.aws_iam_policy_document.backup_policy.json
}
