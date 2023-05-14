#---------------------------------------------#
# Lambda Function                       　    #                                 
#---------------------------------------------#
data "aws_region" "current" {}
data "aws_caller_identity" "self" {}

locals {
  lambdas = [
    {
      name          = "${var.environment}-First-Function"
      source_dir    = "lambda-code/first/"
      zip_file_path = "lambda-zip/first/lambda_function.zip"
      description   = "First for Lambda"
      variables = {
        ENV           = var.environment,
        DB_TABLE_NAME = "example",
        ZOOM_API_KEY  = "example",
        ADMP_API_HOST = "example"
      }
      path_name = "api/v1/first"
    },
    {
      name          = "${var.environment}-Second-Function"
      source_dir    = "lambda-code/second/"
      zip_file_path = "lambda-zip/second/lambda_function.zip"
      description   = "Second for Lambda"
      variables = {
        ENV           = var.environment,
        DB_TABLE_NAME = "example",
        ZOOM_API_KEY  = "example",
        ADMP_API_HOST = "example"
      }
      path_name = "api/v1/second"
    },
    {
      name          = "${var.environment}-Third-Function"
      source_dir    = "lambda-code/third/"
      zip_file_path = "lambda-zip/third/lambda_function.zip"
      description   = "Third for Lambda"
      variables = {
        ENV           = var.environment,
        DB_TABLE_NAME = "example",
        ZOOM_API_KEY  = "example",
        ADMP_API_HOST = "example"
      }
      path_name = "api/v1/third"
    }
  ]
}



// ファイルのZIP化 //
data "archive_file" "function_source" {
  for_each = {
    for idx, arg in local.lambdas : idx => arg
  }

  type        = "zip"
  source_dir  = each.value.source_dir
  output_path = each.value.zip_file_path
}

// Lambda Functions //
resource "aws_lambda_function" "lambda_functions" {
  for_each = {
    for idx, arg in local.lambdas : idx => arg
  }

  description   = each.value.description
  function_name = each.value.name
  handler       = "lambda_function.lambda_handler"
  package_type  = "Zip"
  role          = aws_iam_role.for_lambda.arn
  runtime       = "python3.9"
  timeout       = 3

  filename = data.archive_file.function_source[each.key].output_path

  # 環境変数
  environment {
    variables = each.value.variables
  }
}

// Trigger For Permission//
resource "aws_lambda_permission" "HttpApiIntegrationPermission" {
  for_each = {
    for idx, arg in local.lambdas : idx => arg
  }

  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_functions[each.key].arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:${data.aws_region.current.name}:${data.aws_caller_identity.self.account_id}:${aws_apigatewayv2_api.api_integration.id}/*/*/${each.value.path_name}"
}



#---------------------------------------------#
# IAM for Lambda                        　    #                                 
#---------------------------------------------#
// IAM Role  //
resource "aws_iam_role" "for_lambda" {
  name = "${var.project}-${var.environment}-for-lambda-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

// IAM Policy  //
resource "aws_iam_role_policy" "for_lambda" {
  name   = "${var.project}-${var.environment}-for-lambda-policy"
  role   = aws_iam_role.for_lambda.id
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
      "Effect": "Allow",
      "Resource": "*"
    },
    {
      "Action": [
          "dynamodb:*",
          "secretsmanager:*"
        ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

