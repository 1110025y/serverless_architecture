# ---------------------------------------------#
# DynamoDB Table                               #
# ---------------------------------------------#

locals {
  users_json_data             = file("./template/users_table.json")
  tenants_json_data           = file("./template/tenants_table.json")
  devices_json_data           = file("./template/devices_table.json")
  app_json_data               = file("./template/app_table.json")
  app_communities_json_data   = file("./template/app_communities_table.json")
}

locals {
  dynamodbs = [
    {
      name      = "${var.environment}_users"
      hash_key  = "id"
      json_data = jsondecode(local.users_json_data)
    },
    {
      name      = "${var.environment}_tenants"
      hash_key  = "id"
      json_data = jsondecode(local.tenants_json_data)
    },
    {
      name      = "${var.environment}_devices"
      hash_key  = "id"
      json_data = jsondecode(local.devices_json_data)
    },
    {
      name      = "${var.environment}_applications"
      hash_key  = "id"
      json_data = jsondecode(local.app_json_data)
    },
    {
      name      = "${var.environment}_applications_communities"
      hash_key  = "id"
      json_data = jsondecode(local.app_communities_json_data)
    }
  ]
}

// DynamoDB Table //
resource "aws_dynamodb_table" "db_table" {
  for_each = {
    for idx, arg in local.dynamodbs : idx => arg
  }

  name           = each.value.name
  billing_mode   = "PROVISIONED"
  read_capacity  = var.dynamodb_config.read_capacity
  write_capacity = var.dynamodb_config.write_capacity
  hash_key       = each.value.hash_key

  # Attribute Type - S:文字列、N:数値、B:バイナリ
  # hash_keyとrange_keyのtypeの指定
  attribute {
    name = each.value.hash_key
    type = "S"
  }

  #Point-in-time recoveryの有効化
  point_in_time_recovery {
    enabled = false
  }

  # TTLの設定
  # ttl {
  #   enabled        = false
  #   attribute_name = "TimeToExist"
  # }
}

// DynamoDB Table Items //
resource "aws_dynamodb_table_item" "db_item" {
  for_each = {
    for idx, arg in local.dynamodbs : idx => arg
  }

  table_name = aws_dynamodb_table.db_table[each.key].name
  hash_key   = aws_dynamodb_table.db_table[each.key].hash_key
  item       = jsonencode(each.value.json_data)

  lifecycle {
    ignore_changes = [
      # Ignore changes to item, because JSON File Update Protection.
      # updates these based on some ruleset managed elsewhere.
      item,
    ]
  }
}


// ReadCapacityUnits of DynamoDB Table AutoScaling //
resource "aws_appautoscaling_target" "dynamodb_table_read_target" {
  depends_on = [
    aws_dynamodb_table_item.db_item
  ]

  for_each = {
    for idx, arg in local.dynamodbs : idx => arg
  }

  max_capacity       = var.dynamodb_scaling_config.read_capacity.max
  min_capacity       = var.dynamodb_scaling_config.read_capacity.min
  resource_id        = "table/${each.value.name}"
  scalable_dimension = "dynamodb:table:ReadCapacityUnits"
  service_namespace  = "dynamodb"
}

resource "aws_appautoscaling_policy" "dynamodb_table_read_policy" {
  for_each = {
    for idx, arg in local.dynamodbs : idx => arg
  }

  name               = "DynamoDBReadCapacityUtilization:${aws_appautoscaling_target.dynamodb_table_read_target[each.key].resource_id}"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.dynamodb_table_read_target[each.key].resource_id
  scalable_dimension = aws_appautoscaling_target.dynamodb_table_read_target[each.key].scalable_dimension
  service_namespace  = aws_appautoscaling_target.dynamodb_table_read_target[each.key].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "DynamoDBReadCapacityUtilization"
    }

    target_value = var.dynamodb_scaling_config.read_capacity.target_value
  }
}

// WriteCapacityUnits of DynamoDB Table AutoScaling //
resource "aws_appautoscaling_target" "dynamodb_table_write_target" {
  depends_on = [
    aws_dynamodb_table_item.db_item
  ]

  for_each = {
    for idx, arg in local.dynamodbs : idx => arg
  }

  max_capacity       = var.dynamodb_scaling_config.write_capacity.max
  min_capacity       = var.dynamodb_scaling_config.write_capacity.min
  resource_id        = "table/${each.value.name}"
  scalable_dimension = "dynamodb:table:WriteCapacityUnits"
  service_namespace  = "dynamodb"
}

resource "aws_appautoscaling_policy" "dynamodb_table_write_policy" {
  for_each = {
    for idx, arg in local.dynamodbs : idx => arg
  }

  name               = "DynamoDBWriteCapacityUtilization:${aws_appautoscaling_target.dynamodb_table_write_target[each.key].resource_id}"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.dynamodb_table_write_target[each.key].resource_id
  scalable_dimension = aws_appautoscaling_target.dynamodb_table_write_target[each.key].scalable_dimension
  service_namespace  = aws_appautoscaling_target.dynamodb_table_write_target[each.key].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "DynamoDBWriteCapacityUtilization"
    }

    target_value = var.dynamodb_scaling_config.write_capacity.target_value
  }
}