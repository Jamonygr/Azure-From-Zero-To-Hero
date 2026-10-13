locals {
  lab_id         = "CLZ-330"
  prefix         = lower("${var.name_prefix}-${var.environment}-clz330")
  compact_prefix = substr(replace(local.prefix, "-", ""), 0, 20)

  tags = {
    Project     = "Azure From Zero To Hero"
    Environment = var.environment
    ManagedBy   = "Terraform"
    Lab         = local.lab_id
  }
}
