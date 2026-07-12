locals {
  lab_id = "CLZ-110"

  account_selection_command = var.subscription_id == null ? null : "az account set --subscription ${var.subscription_id}"
  readiness_commands = compact([
    "az version",
    "az login",
    local.account_selection_command,
    "az account show --query '{name:name,id:id,tenantId:tenantId,state:state}' --output table",
    "az account list-locations --query \"[?name=='${var.location}'].{Name:name,DisplayName:displayName}\" --output table",
    "az provider show --namespace Microsoft.Compute --query registrationState --output tsv",
    "az vm list-usage --location ${var.location} --output table",
    "az role assignment list --assignee \"$(az ad signed-in-user show --query id --output tsv)\" --scope \"/subscriptions/$(az account show --query id --output tsv)\" --output table",
  ])
}
