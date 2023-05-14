#---------------------------------------------#
# API Getway For ADMP Integration             #                         
#---------------------------------------------#

locals {
  title                   = "Http-Api-Integration"
  first_lambda = aws_lambda_function.lambda_functions["0"].arn
  second_lambda      = aws_lambda_function.lambda_functions["1"].arn
  third_lambda    = aws_lambda_function.lambda_functions["2"].arn
}


// Create HTTP API //
resource "aws_apigatewayv2_api" "api_integration" {
  depends_on = [
    aws_lambda_function.lambda_functions
  ]

  name          = "${var.environment}-HTTP-Api-Integration"
  protocol_type = "HTTP"

  body = data.template_file.api_integration.rendered
}

// Swagger File の作成 //
data "template_file" "api_integration" {
  template = file("./openAPI/api-integration.yaml")

  vars = {
    title                   = local.title
    first_lambda = local.first_lambda
    second_lambda      = local.second_lambda
    third_lambda    = local.third_lambda
  }
}

// Create Stage for Deployment //
resource "aws_apigatewayv2_stage" "api_integration" {
  api_id = aws_apigatewayv2_api.api_integration.id
  #name   = "$default"
  name        = var.apigateway_config.stage
  auto_deploy = true
  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.apigetway_log.arn
    format = jsonencode(
      {
        httpMethod     = "$context.httpMethod"
        ip             = "$context.identity.sourceIp"
        protocol       = "$context.protocol"
        requestId      = "$context.requestId"
        requestTime    = "$context.requestTime"
        responseLength = "$context.responseLength"
        routeKey       = "$context.routeKey"
        status         = "$context.status"
      }
    )
  }
}

// API Deployment Setting //
resource "aws_apigatewayv2_deployment" "api_integration" {
  api_id = aws_apigatewayv2_api.api_integration.id

  # yamlファイルの内容変更をした後、applyすれば情報が更新されリソース(Api Getway)が再デプロイされる
  triggers = {
    redeployment = sha1(file("./openAPI/api-integration.yaml"))
  }

  # 既存のリソースがあった場合に、先に削除してから作り直す設定(これがないと再デプロイがエラーになる)
  lifecycle {
    create_before_destroy = true
  }
}



// API Getway Authorization(JWTトークン認証使用) //
/*
resource "aws_apigatewayv2_authorizer" "api_integration" {

  api_id                            = aws_apigatewayv2_api.api_integration.id
  authorizer_type                   = "JWT"
  identity_sources                  = ["$request.header.Authorization"]
  name                              = "${var.environment}-JWT-integration"
  authorizer_payload_format_version = "2.0"
  
  jwt_configuration  {
    # 対象者
    audience= [
      "Audience"
    ]
    # Cognito poolのURL
    issuer= "「Cognito PoolのURLを入力」"
  }
}
*/


#---------------------------------------------#
# API Access_logs for Cloudwatch logs         #
#---------------------------------------------#
resource "aws_cloudwatch_log_group" "apigetway_log" {
  name              = "/aws/${var.project}/${var.environment}/apigetway-logs"
  retention_in_days = var.apigateway_config.retention_days
}
