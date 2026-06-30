# Support

Azure From Zero To Hero is a learning repository. The best support path is to open a focused GitHub issue with enough detail for someone else to reproduce the problem.

## Good Support Requests Include

- Lesson folder, for example `CLZ-210-azure-bastion-rdp`.
- Operating system and PowerShell version.
- Terraform version and Azure CLI version.
- The command that failed.
- Sanitized error output.
- What you expected to happen.
- Whether resources were already created in the subscription.

## Choose The Right Request Type

- Use lesson feedback when the steps are confusing, incomplete, or out of order.
- Use a bug report when a command, script, link, or Terraform validation step fails.
- Use a feature request when you want a new Azure pattern, diagram, or lesson.
- Use a pull request when you already have a focused fix.

## Before Opening An Issue

~~~powershell
terraform fmt
terraform validate
.\scripts\Test-AzureFromZeroToHeroDocs.ps1 -ReportPath artifacts\repo-quality-report.json
~~~

For cost or cleanup problems, include the lesson folder and the Azure resources still present after `terraform destroy`.
