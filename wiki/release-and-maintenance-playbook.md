# Release And Maintenance Playbook

Use this playbook when preparing broad curriculum updates, dependency refreshes, or repository releases.

## Local Preflight

From the repository root:

~~~powershell
.\scripts\Test-AzureFromZeroToHeroQuality.ps1 -ReportPath artifacts\quality-report.json
~~~

Repository automation does not run Azure plans. When a release requires cloud
evidence, an authorized maintainer selects the subscription by ID and follows
the [manual Azure smoke matrix](manual-azure-smoke-matrix.md):

~~~powershell
$subscriptionId = az account show --query id --output tsv
az account show --query '{tenant:tenantId,subscription:id,user:user.name}' --output table
~~~

## Pull Request Review

Check that each change has:

- A clear learning reason.
- Terraform formatted with stable examples.
- No committed secrets, tenant details, state files, plans, or local overrides.
- Updated diagrams or docs when architecture changes.
- Updated cleanup guidance when resource shape changes.
- Passing GitHub Actions checks or documented local evidence.

## Dependency Updates

Dependabot groups GitHub Actions and Terraform provider updates. For provider updates:

1. Review the provider changelog before merging.
2. Run Terraform format and validation.
3. Regenerate and inspect the committed root-module lockfiles for Windows and Linux AMD64.
4. Add a troubleshooting note when provider behavior changes learner-facing commands.

## Issue Triage

Label incoming issues by lesson, area, and request type where possible:

- `lesson`
- `bug`
- `documentation`
- `terraform`
- `powershell`
- `security`
- `cost`
- `question`

Ask for sanitized command output when an issue cannot be reproduced from the report.

## Release Notes

A release note should include:

- New or changed lessons.
- Important validation changes.
- Security or cost guidance changes.
- Breaking changes in commands, variables, or required tooling.
- Known limitations and follow-up work.
