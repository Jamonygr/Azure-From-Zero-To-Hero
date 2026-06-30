# Security Policy

This repository is a hands-on Azure and Terraform learning project. The examples are designed for lab subscriptions and should be reviewed before use in production environments.

## Supported Scope

Security reports are welcome for:

- Terraform examples in `CLZ-*` lesson folders.
- Reusable modules under `modules/`.
- PowerShell scripts under `scripts/`.
- GitHub Actions workflows and repository configuration.
- Documentation that could cause unsafe handling of secrets, access, networking, or cleanup.

## Reporting A Vulnerability

Use GitHub's private vulnerability reporting flow if it is enabled for this repository. If private reporting is not available and the issue does not contain secrets or tenant-specific details, open a GitHub issue with a clear reproduction path.

Do not post credentials, subscription IDs, tenant IDs, private IP ranges from real environments, access tokens, certificates, or screenshots that reveal private cloud data.

## Lab Safety Baseline

- Use a dedicated Azure lab subscription when possible.
- Prefer the sample `terraform.tfvars.example` files and never commit real `terraform.tfvars` files.
- Rotate any credential that was pasted into a terminal, issue, pull request, or commit by mistake.
- Run `terraform plan` before `terraform apply`.
- Run `terraform destroy` after each lab unless the next lesson explicitly depends on the resources.
- Review public IPs, firewall rules, NSGs, and DNS records before applying changes.
- Treat generated reports under `artifacts/` as local output unless they have been reviewed for sensitive data.

## Automated Checks

The repository uses Terraform validation, Markdown linting, PowerShell analysis, TFLint, Trivy configuration scanning, and Dependabot updates. Run the local quality gate before broad changes:

~~~powershell
.\scripts\Test-AzureFromZeroToHeroQuality.ps1 -ReportPath artifacts\quality-report.json
~~~
