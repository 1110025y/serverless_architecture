#---------------------------------------------#
# WAF                                         #
#---------------------------------------------#
resource "aws_wafv2_web_acl" "waf_cloudfront" {
  count = var.waf_config["enable"] ? 1 : 0

  provider = aws.virginia
  name     = "${var.project}-${var.environment}-cloudFront-waf"
  scope    = "CLOUDFRONT"

  default_action {
    block {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.project}-${var.environment}-cloudFront-waf-Default"
    sampled_requests_enabled   = true
  }

  # Ip Whitelist
  dynamic "rule" {
    for_each = var.waf_config.whitelist ? { acl = "is_enable" } : {}
    content {

      name     = "IP_Whitelist_rule"
      priority = 0

      action {
        allow {}
      }

      statement {
        ip_set_reference_statement {
          arn = aws_wafv2_ip_set.waf_ip_whitelist[count.index].arn
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "${var.project}-${var.environment}-ip-whitelist"
        sampled_requests_enabled   = true
      }
    }
  }
}


#---------------------------------------------#
# logging_configuration                        #
#---------------------------------------------#
resource "aws_wafv2_web_acl_logging_configuration" "waf_config_cloudfront" {
  count                   = var.waf_config["enable"] ? 1 : 0
  provider                = aws.virginia
  log_destination_configs = [aws_cloudwatch_log_group.waf_log_cloudfront[count.index].arn]
  resource_arn            = aws_wafv2_web_acl.waf_acl_cloudfront[count.index].arn
}

#---------------------------------------------#
# cloudwatch logs                             #
#---------------------------------------------#
resource "aws_cloudwatch_log_group" "waf_log_cloudfront" {
  count             = var.waf_config["enable"] ? 1 : 0
  provider          = aws.virginia
  name              = "aws-waf-logs-${var.project}-${var.environment}-cloudFront"
  retention_in_days = var.waf_config.retention_days
}

#---------------------------------------------#
# IP whitelist                                # 
#---------------------------------------------#
resource "aws_wafv2_ip_set" "waf_ip_whitelist" {
  count              = var.waf_config["enable"] ? 1 : 0
  provider           = aws.virginia
  name               = "Ip-Whitelist"
  scope              = "CLOUDFRONT"
  ip_address_version = "IPV4"
  addresses          = var.ip_list
}

