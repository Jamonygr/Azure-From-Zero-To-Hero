locals {
  lab_id     = "CLZ-210"
  lab_number = replace(local.lab_id, "CLZ-", "")
  lab_code   = lower(replace(local.lab_id, "CLZ-", "clz"))
  prefix     = "${var.name_prefix}-${var.environment}-${local.lab_code}"

  tags = {
    Project     = "Azure From Zero To Hero"
    Environment = var.environment
    ManagedBy   = "Terraform"
    Lab         = local.lab_id
  }
}
