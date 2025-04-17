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
  for_each = toset(var.role_name_prefixes)
  name     = "${each.value}-backup-user"
}

resource "aws_iam_access_key" "backup_access_key" {
  for_each = toset(var.role_name_prefixes)
  user     = aws_iam_user.backup_user[each.key].name
}

resource "aws_s3_bucket" "backup_bucket" {
  for_each = toset(var.role_name_prefixes)
  bucket   = "${each.value}-backup-bucket"
  lifecycle {
    prevent_destroy = true # Must be destroyed in the console.
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "expire_old_backups" {
  for_each = toset(var.role_name_prefixes)
  bucket   = aws_s3_bucket.backup_bucket[each.key].id
  rule {
    id     = "expire-old-backups"
    status = "Enabled"
    filter {
      prefix = ".tar.gz"
    }
    expiration {
      days = 30
    }
  }
}

resource "aws_s3_bucket_policy" "backup_bucket_policy" {
  for_each = toset(var.role_name_prefixes)
  bucket   = aws_s3_bucket.backup_bucket[each.key].id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_user.backup_user[each.key].arn
        }
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket",
        ]
        Resource = [
          "arn:aws:s3:::${aws_s3_bucket.backup_bucket[each.key].id}",
          "arn:aws:s3:::${aws_s3_bucket.backup_bucket[each.key].id}/*",
        ]
      },
    ]
  })
}

resource "aws_s3_bucket_public_access_block" "backup_bucket_public_access_block" {
  for_each = toset(var.role_name_prefixes)
  bucket   = aws_s3_bucket.backup_bucket[each.key].id

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "backup_bucket_versioning" {
  for_each = toset(var.role_name_prefixes)
  bucket   = aws_s3_bucket.backup_bucket[each.key].id
  versioning_configuration {
    status = "Enabled"
  }
}

data "aws_iam_policy_document" "backup_policy" {
  for_each = toset(var.role_name_prefixes)
  statement {
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:ListBucket",
    ]
    resources = [
      "arn:aws:s3:::${aws_s3_bucket.backup_bucket[each.key].id}",
      "arn:aws:s3:::${aws_s3_bucket.backup_bucket[each.key].id}/*",
    ]
  }
}

resource "aws_iam_user_policy" "backup_user_policy" {
  for_each = toset(var.role_name_prefixes)

  name   = "${each.value}-backup-policy"
  user   = aws_iam_user.backup_user[each.key].id
  policy = data.aws_iam_policy_document.backup_policy[each.key].json
}
