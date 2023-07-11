# ---------------------------------------------#
# S3 for static site                           #
# ---------------------------------------------#
resource "aws_s3_bucket" "static_site" {
  bucket = "${var.project}-${var.environment}-static-site-contents"
}

// バージョニングの有効/無効 //
resource "aws_s3_bucket_versioning" "static_site" {
  bucket = aws_s3_bucket.static_site.id
  versioning_configuration {
    status = var.s3_config.static_site.versioning
  }
}

// アクセスブロック (バケット設定) //
resource "aws_s3_bucket_public_access_block" "static_site" {
  bucket = aws_s3_bucket.static_site.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  depends_on = [
    aws_s3_bucket_policy.static_site
  ]
}

// サーバー側の暗号化 //
resource "aws_s3_bucket_server_side_encryption_configuration" "static_site" {
  bucket = aws_s3_bucket.static_site.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

// S3バケットの（ACL設定）//
resource "aws_s3_bucket_ownership_controls" "static_site" {
  bucket = aws_s3_bucket.static_site.id
  rule {
    object_ownership = var.s3_config.static_site.ownership
  }
}

// バケットポリシー //
resource "aws_s3_bucket_policy" "static_site" {
  count  = var.s3_config.static_site["enable"] ? 1 : 0
  bucket = aws_s3_bucket.static_site.id
  policy = data.aws_iam_policy_document.static_site_bucket_policy[count.index].json
}

data "aws_iam_policy_document" "static_site_bucket_policy" {
  count = var.s3_config.static_site["enable"] ? 1 : 0
  statement {
    effect  = "Allow"
    actions = ["s3:GetObject"]
    resources = [
      "${aws_s3_bucket.static_site.arn}/*",
      "${aws_s3_bucket.static_site.arn}"
    ]
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    # valuesに設定したCloudFrontと一致しているかどうかの確認
    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = [aws_cloudfront_distribution.distribution[count.index].arn]
    }
  }
}


# ---------------------------------------------#
# S3 for CloudFront Accesslogs                 #
# ---------------------------------------------#
resource "aws_s3_bucket" "cloudfront_logs" {
  count  = var.s3_config.cloudfront_logs["enable"] ? 1 : 0
  bucket = "${var.project}-${var.environment}-cloudfront-log"
}

// バージョニングの有効/無効 //
resource "aws_s3_bucket_versioning" "cloudfront_logs" {
  count = var.s3_config.cloudfront_logs["enable"] ? 1 : 0

  bucket = aws_s3_bucket.cloudfront_logs[count.index].id
  versioning_configuration {
    status = var.s3_config.cloudfront_logs.versioning
  }
}


// サーバー側の暗号化 //
resource "aws_s3_bucket_server_side_encryption_configuration" "cloudfront_logs" {
  count = var.s3_config.cloudfront_logs["enable"] ? 1 : 0

  bucket = aws_s3_bucket.cloudfront_logs[count.index].id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

// S3バケットの（ACL設定）//
resource "aws_s3_bucket_ownership_controls" "cloudfront_logs" {
  count = var.s3_config.cloudfront_logs["enable"] ? 1 : 0

  bucket = aws_s3_bucket.cloudfront_logs[count.index].id
  rule {
    object_ownership = var.s3_config.cloudfront_logs.ownership
  }
}

// S3バケットACLリソース //

# AWSアカウントの正規のユーザIDを取得
data "aws_canonical_user_id" "current" {}

resource "aws_s3_bucket_acl" "cloudfront_logs" {
  count = var.s3_config.cloudfront_logs["enable"] ? 1 : 0

  bucket = aws_s3_bucket.cloudfront_logs[count.index].id
  access_control_policy {
    # バケット所有者（自身のAWSアカウントの許可設定）の許可設定
    grant {
      grantee {
        id   = data.aws_canonical_user_id.current.id
        type = "CanonicalUser"
      }
      permission = "FULL_CONTROL"
    }
    # awslogsdeliveryアカウントIDの許可設定(外部アカウント)
    grant {
      grantee {
        # awslogsdeliveryアカウントのID
        id   = ""
        type = "CanonicalUser"
      }
      permission = "FULL_CONTROL"
    }
    # バケットの所有者の正規ユーザーIDの設定
    owner {
      id = data.aws_canonical_user_id.current.id
    }
  }
}
