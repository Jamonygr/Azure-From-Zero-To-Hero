# Contributing

Azure From Zero To Hero is organized as small, readable Terraform lessons. Keep contributions focused and easy to validate.

## Contribution Flow

1. Pick one lesson, script, wiki page, or workflow area.
2. Make the smallest complete change that improves the learning path.
3. Run the checks that match the change.
4. Open a pull request with the validation evidence.

## Standards

- Use PowerShell examples.
- Keep lesson folders independently deployable.
- Commit only safe example values.
- Keep diagrams, README files, variables, outputs, and cleanup notes aligned.
- Prefer explicit learner guidance over unexplained automation.
- Run `.\scripts\Test-AzureFromZeroToHeroQuality.ps1 -ReportPath artifacts\quality-report.json` before pushing broad changes.
- If a quality tool is missing locally, install it or run the matching GitHub Actions job before merging.

## Documentation

Every lesson README should include a goal, architecture image, build summary, runbook, validation checklist, cleanup note, and next lesson pointer. When architecture changes, update the matching diagram or explain why the existing diagram is still accurate.

## Quality Tools

- Terraform validation stays backend-free by default and does not run `terraform apply`.
- Markdown linting uses `markdownlint-cli2` with repo settings.
- PowerShell checks use PSScriptAnalyzer with repo settings.
- TFLint runs with the AzureRM ruleset and only fails on error-level findings.
- Trivy reports Terraform security findings and blocks critical issues by default.

## Safety Review

Before opening a pull request, confirm the change does not include:

- Real `terraform.tfvars` files.
- State files or plan files.
- Credentials, access tokens, tenant IDs, subscription IDs, or private hostnames.
- Screenshots that reveal private Azure data.
- Public inbound access that is not explained in the lesson.

## Review Checklist

- The learning goal is clear.
- The Terraform is formatted and readable.
- The sample values are safe for a public repository.
- The validation and cleanup steps still work.
- The change fits the Windows and PowerShell path.

