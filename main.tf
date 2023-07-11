#---------------------------------------------#
# terraform setting                           #
#---------------------------------------------#
terraform {
  required_version = ">=0.13"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.1.0"
    }
  }

  backend "s3" {
  }
}

#---------------------------------------------#
# provider setting                            #
#---------------------------------------------#
provider "aws" {
  region = "ap-northeast-1"
  assume_role {
    role_arn = var.aws_switchrole_arn
  }

  default_tags {
    tags = {
      Project     = var.project
      Environment = var.environment
    }
  }
}

provider "aws" {
  alias  = "virginia"
  region = "us-east-1"
  assume_role {
    role_arn = var.aws_switchrole_arn
  }
  default_tags {
    tags = {
      Project     = var.project
      Environment = var.environment
    }
  }
}


#---------------------------------------------#
# Global Variables                            #
#---------------------------------------------#
variable "environment" {}
variable "project" {}
variable "aws_switchrole_arn" {}

#---------------------------------------------#
# Secret Manager                              #
#---------------------------------------------#
variable "secret_manager_config" {
  type = map(any)
}

#---------------------------------------------#
# Cognito                                     #
#---------------------------------------------#
variable "cognito_config" {
  type = map(any)
}

#---------------------------------------------#
# API Getway                                  #
#---------------------------------------------#
variable "apigateway_config" {
  type = map(string)
}

#---------------------------------------------#
# CloudFront                                  #
#---------------------------------------------#
variable "cdn_config" {
  type = map(any)
}

#---------------------------------------------#
# DynamoDB Table                              #
#---------------------------------------------#
variable "dynamodb_scaling_config" {
  type = map(any)
}

#---------------------------------------------#
# IP Whitelist                                #
#---------------------------------------------#
variable "ip_list" {
  type = list(any)
}

#---------------------------------------------#
# Route53                                     #
#---------------------------------------------#
variable "domain_config" {
  type = map(any)
}

#---------------------------------------------#
# S3                                          #
#---------------------------------------------#
variable "s3_config" {
  type = map(any)
}

#---------------------------------------------#
# WAF                                         #
#---------------------------------------------#
variable "waf_config" {
  type = map(any)
}

