resource "aws_db_parameter_group" "main" {
  name   = "${var.identifier}-pg"
  family = var.parameter_group_family

  dynamic "parameter" {
    for_each = var.parameters
    content {
      name         = parameter.value.name
      value        = parameter.value.value
      apply_method = lookup(parameter.value, "apply_method", "immediate")
    }
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.identifier}-parameter-group"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_db_option_group" "main" {
  count = var.create_option_group ? 1 : 0

  name                     = "${var.identifier}-og"
  engine_name              = "postgres"
  major_engine_version     = var.major_engine_version
  option_group_description = "Option group for ${var.identifier}"

  dynamic "option" {
    for_each = var.options
    content {
      option_name = option.value.option_name

      dynamic "option_settings" {
        for_each = lookup(option.value, "option_settings", [])
        content {
          name  = option_settings.value.name
          value = option_settings.value.value
        }
      }
    }
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.identifier}-option-group"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}
