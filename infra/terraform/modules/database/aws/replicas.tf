resource "aws_db_instance" "read_replica" {
  count = var.create_read_replica ? var.read_replica_count : 0

  identifier     = "${var.identifier}-replica-${count.index + 1}"
  replicate_source_db = aws_db_instance.main.identifier

  instance_class    = var.read_replica_instance_class != null ? var.read_replica_instance_class : var.instance_class
  storage_encrypted = true
  kms_key_id        = var.kms_key_arn

  multi_az            = var.read_replica_multi_az
  publicly_accessible = false

  vpc_security_group_ids = concat([var.rds_security_group_id], var.additional_security_group_ids)

  parameter_group_name = aws_db_parameter_group.main.name

  backup_retention_period = 0
  skip_final_snapshot     = true

  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs_exports

  performance_insights_enabled          = var.performance_insights_enabled
  performance_insights_retention_period = var.performance_insights_enabled ? var.performance_insights_retention_period : null
  performance_insights_kms_key_id       = var.performance_insights_enabled ? var.kms_key_arn : null

  monitoring_interval = var.monitoring_interval
  monitoring_role_arn = var.monitoring_interval > 0 ? var.monitoring_role_arn : null

  auto_minor_version_upgrade = var.auto_minor_version_upgrade
  apply_immediately          = var.apply_immediately

  max_allocated_storage = var.max_allocated_storage

  ca_cert_identifier = var.ca_cert_identifier

  tags = merge(
    var.tags,
    {
      Name    = "${var.identifier}-replica-${count.index + 1}"
      Replica = "true"
    }
  )

  depends_on = [
    aws_db_instance.main
  ]
}

resource "aws_db_instance" "cross_region_replica" {
  count = var.create_cross_region_replica ? 1 : 0

  provider = aws.replica_region

  identifier     = "${var.identifier}-cross-region-replica"
  replicate_source_db = aws_db_instance.main.arn

  instance_class    = var.cross_region_replica_instance_class != null ? var.cross_region_replica_instance_class : var.instance_class
  storage_encrypted = true
  kms_key_id        = var.cross_region_kms_key_arn

  multi_az            = var.cross_region_replica_multi_az
  publicly_accessible = false

  parameter_group_name = "${var.identifier}-cross-region-pg"

  backup_retention_period = var.cross_region_replica_backup_retention
  skip_final_snapshot     = true

  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs_exports

  performance_insights_enabled = var.performance_insights_enabled

  monitoring_interval = var.monitoring_interval
  monitoring_role_arn = var.monitoring_interval > 0 ? var.cross_region_monitoring_role_arn : null

  auto_minor_version_upgrade = var.auto_minor_version_upgrade
  apply_immediately          = var.apply_immediately

  tags = merge(
    var.tags,
    {
      Name          = "${var.identifier}-cross-region-replica"
      Replica       = "true"
      CrossRegion   = "true"
    }
  )

  depends_on = [
    aws_db_instance.main
  ]
}
