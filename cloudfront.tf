# ---------------------------------------------#
# CloudFront distribution                      #
# ---------------------------------------------#
resource "aws_cloudfront_distribution" "distribution" {
  count = var.cdn_config["enable"] ? 1 : 0

  enabled         = var.cdn_config.distribution
  is_ipv6_enabled = false
  price_class     = "PriceClass_All"

  default_root_object = "index.html"

  // Origin Setting For S3 //
  origin {
    domain_name = aws_s3_bucket.static_site.bucket_regional_domain_name
    origin_id   = aws_s3_bucket.static_site.id

    // OAC を設定
    origin_access_control_id = aws_cloudfront_origin_access_control.oac_for_s3[count.index].id
  }

  // DefaultのOrigin(S3)への転送設定 or キャッシュ動作設定 //
  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = aws_s3_bucket.static_site.id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }


  // 追加のOrigin(S3)への転送設定 or キャッシュ動作設定 //
  ordered_cache_behavior {
    path_pattern     = "/"
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = aws_s3_bucket.static_site.id

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 86400    # 1日
    max_ttl                = 31536000 # 1年
    compress               = true
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    #acm_certificate_arn            = ""
    #minimum_protocol_version       = "TLSv1.2_2021"
    #cloudfront_default_certificate = false
    cloudfront_default_certificate = true
    minimum_protocol_version = "TLSv1"
    ssl_support_method             = "sni-only"
  }

  web_acl_id = aws_wafv2_web_acl.waf_cloudfront[count.index].arn

  // Access_logs Setting //
  logging_config {
    bucket = aws_s3_bucket.cloudfront_logs[count.index].bucket_domain_name
    // access_logsにCookieを含めるかどうかの設定
    include_cookies = true
    // access_logs_fileの前につけるオプションの文字列
    prefix = "${var.project}/${var.environment}/cloudfront-logs"
  }
}

# ---------------------------------------------#
# Origin_Access_Control                        #
# ---------------------------------------------#
resource "aws_cloudfront_origin_access_control" "oac_for_s3" {
  count                             = var.cdn_config["enable"] ? 1 : 0
  name                              = "${var.project}-${var.environment}-oac"
  description                       = "origin_access_control"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}
