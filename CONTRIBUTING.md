# Contributing

Azure From Zero To Hero is organized as small, readable Terraform lessons. Keep contributions focused and easy to validate.

## Standards
- Use PowerShell examples.
- Keep lesson folders independently deployable.
- Commit only safe example values.
- Run `.\scripts\Test-AzureFromZeroToHeroQuality.ps1 -ReportPath artifacts\quality-report.json` before pushing broad changes.
- If a quality tool is missing locally, install it or run the matching GitHub Actions job before merging.

## Documentation
Every lesson README should include a goal, architecture image, build summary, runbook, validation checklist, cleanup note, and next lesson pointer.

## Quality Tools
- Terraform validation stays backend-free by default and does not run `terraform apply`.
- Markdown linting uses `markdownlint-cli2` with repo settings.
- PowerShell checks use PSScriptAnalyzer with repo settings.
- TFLint runs with the AzureRM ruleset and only fails on error-level findings.
- Trivy reports Terraform security findings and blocks critical issues by default.

