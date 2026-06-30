# Release And Maintenance Playbook

Use this playbook when preparing broad curriculum updates, dependency refreshes, or repository releases.

## Local Preflight

From the repository root:

~~~powershell
.\scripts\Test-AzureFromZeroToHeroQuality.ps1 -ReportPath artifacts\quality-report.json
~~~

For Azure-authenticated validation, run optional safe plan checks only when the subscription context is correct:

~~~powershell
az account show
.\scripts\Test-AzureFromZeroToHeroTerraform.ps1 -PlanSafeLessons -ReportPath artifacts\terraform-plan-report.json
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
3. Inspect any changed lock files if lock files are intentionally introduced later.
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
