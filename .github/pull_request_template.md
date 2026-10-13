# Pull Request

## What Changed

- Summarize the change.

## Why It Matters

- Explain the learner or maintainer impact.

## Validation

- [ ] `terraform fmt -check`
- [ ] `terraform validate`
- [ ] `.\scripts\Test-AzureFromZeroToHeroDocs.ps1 -ReportPath artifacts\repo-quality-report.json`
- [ ] `.\scripts\Test-AzureFromZeroToHeroQuality.ps1 -ReportPath artifacts\quality-report.json`
- [ ] Not applicable because:

## Safety

- [ ] No secrets, tenant IDs, subscription IDs, state files, plan files, or local variable files are included.
- [ ] Cost and cleanup guidance still matches the resources created.
- [ ] Diagrams and README content match Terraform behavior.
