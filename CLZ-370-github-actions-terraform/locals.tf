locals {
  lab_id = "CLZ-370"
  prefix = lower("${var.name_prefix}-${var.environment}-clz370")

  tags = {
    Project     = "Azure From Zero To Hero"
    Environment = var.environment
    ManagedBy   = "Terraform"
    Lab         = local.lab_id
  }
}
