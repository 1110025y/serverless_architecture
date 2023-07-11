#---------------------------------------------#
# Global                                      #
#---------------------------------------------#
environment        = "dev"
project            = "sample"
aws_switchrole_arn = "arn:aws:iam::123456789123:role/switch-role"

#---------------------------------------------#
# Secret Manager                              #
#---------------------------------------------#
secret_manager_config = {
  enable = true
}

#---------------------------------------------#
# Cognito                                     #
#---------------------------------------------#
cognito_config = {
  user_pool = {
    enable = true
  }
}

#---------------------------------------------#
# API Getway                                  #
#---------------------------------------------#
apigateway_config = {
  stage          = "dev"
  retention_days = 30
}


#---------------------------------------------#
# CloudFront                                  #
#---------------------------------------------#
cdn_config = {
  enable       = true
  distribution = true
}


#---------------------------------------------#
# DynamoDB Table                              #
#---------------------------------------------#
dynamodb_scaling_config = {
  read_capacity = {
    max          = 20
    min          = 1
    target_value = 50
  }

  write_capacity = {
    max          = 20
    min          = 1
    target_value = 50
  }
}


#---------------------------------------------#
# IP Whitelist                                #
#---------------------------------------------#
ip_list = [
  "192.168.0.0/32",
]

#---------------------------------------------#
# S3                                          #
#---------------------------------------------#
s3_config = {

  static_site = {
    enable     = true
    versioning = "Disabled"
    ownership  = "BucketOwnerEnforced"
  }

  cloudfront_logs = {
    enable     = true
    versioning = "Disabled"
    ownership  = "BucketOwnerPreferred"
  }
}


#---------------------------------------------#
# WAF                                         #
#---------------------------------------------#
waf_config = {
  enable         = true
  whitelist      = true
  retention_days = "30"
}


