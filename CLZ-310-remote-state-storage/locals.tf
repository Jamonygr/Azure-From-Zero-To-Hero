locals {
  lab_id         = "CLZ-310"
  prefix         = lower("${var.name_prefix}-${var.environment}-clz310")
  compact_prefix = substr(replace(local.prefix, "-", ""), 0, 12)

  tags = {
    Project     = "Azure From Zero To Hero"
    Environment = var.environment
    ManagedBy   = "Terraform"
    Lab         = local.lab_id
  }
}
