# Contributing

Azure From Zero To Hero is organized as small, readable Terraform lessons. Keep contributions focused and easy to validate.

## Contribution Flow

1. Pick one lesson, script, wiki page, or workflow area.
2. Make the smallest complete change that improves the learning path.
3. Run the checks that match the change.
4. Open a pull request with the validation evidence.

## Standards

- Use PowerShell examples.
- Keep deployable lesson folders self-contained except for cataloged exercises
  such as the intentional CLZ-310 to CLZ-320 remote-state dependency. Keep
  local/readiness lessons credential-free.
- Commit only safe example values.
- Keep diagrams, README files, variables, outputs, and cleanup notes aligned.
- Prefer explicit learner guidance over unexplained automation.
- Run `.\scripts\Test-AzureFromZeroToHeroQuality.ps1 -ReportPath artifacts\quality-report.json` before pushing broad changes.
- If a quality tool is missing locally, install it or run the matching GitHub Actions job before merging.

## Documentation

Every lesson README uses these exact second-level headings: `Goal`,
`Prerequisites`, `Architecture`, `Resources And Cost`, `Inputs`, `Deploy`,
`Validate`, `Troubleshooting`, `Cleanup`, `Production Delta`, `Exercises`, and
`Navigation`. Validation must include commands and expected results; cleanup
must prove the resources are gone.

`curriculum/lessons.psd1` is the source of truth for lesson metadata. After a
title, dependency, diagram, cost, deployment-mode, or navigation change, run:

```powershell
./scripts/Sync-AzureFromZeroToHeroCurriculum.ps1 -Write
./scripts/Sync-AzureFromZeroToHeroCurriculum.ps1 -Check
```

The sync script changes only marked curriculum and navigation blocks. Create a
single appended lesson with `New-AzureFromZeroToHeroLesson.ps1`; do not restore
the retired repository-wide scaffold/overwrite generator. When architecture
changes, update the matching diagram or explain why it still applies.

## Quality Tools

- Terraform validation stays backend-free by default and does not run `terraform apply`.
- Markdown linting uses `markdownlint-cli2` with repo settings.
- PowerShell checks use PSScriptAnalyzer with repo settings.
- TFLint warnings and errors fail the quality gate.
- Trivy blocks undocumented MEDIUM, HIGH, and CRITICAL Terraform findings.
- `actionlint`, Pester, curriculum drift, and unused-variable checks run in the
  contributor gate.

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


## Illustrated Website Contributions

`curriculum/lessons.psd1` remains the lesson catalog. Import it through
`scripts/Export-LearningCatalog.ps1`; do not maintain a second editable list.
Website staging, builds, virtual environments, plans, state, and learner exports
are local generated data and must remain ignored.

```powershell
python -m pip install -r requirements-site.txt
python tools/validate_assessments.py
python tools/render_site_visuals.py --check
node --test tools/tests/browser_learning.test.cjs
python tools/build_docs_site.py
python -m mkdocs build --strict
python tools/check_built_site.py
```

Question banks contain 30 original questions per assessed lesson, with four
options, one answer, explanations, official references, and a lesson remediation
anchor. Validate against `assessments/question-bank.schema.json`; review accuracy
against the lesson Terraform and current official documentation. CLZ-090 uses a
setup checklist. Never add an assessment that claims live Azure validation.

Progress uses `azureZeroToHeroLearnerProgress.v1` and version `1.0.0` JSON exports.
Quiz scoring must preserve lesson status and self-reported exercise and cleanup
fields. The website sends no progress to a server. Retain this format when
changing the learning interface.
