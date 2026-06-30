# Roadmap

This roadmap keeps the project moving toward a polished Azure learning experience while preserving its beginner-friendly lesson flow.

## Current Focus

- Keep every lesson independently readable and deployable.
- Strengthen private access, secret handling, cleanup, and cost awareness.
- Keep diagrams aligned with the Terraform patterns.
- Maintain local and GitHub Actions quality gates.
- Improve issue triage so learner feedback turns into actionable fixes.

## Near-Term Improvements

- Add more validation notes for Azure quota and region availability.
- Add optional policy examples for lab subscriptions.
- Add lesson-level expected output examples for common Terraform commands.
- Add more troubleshooting entries based on recurring learner questions.
- Add a short migration note when provider behavior changes.

## Later Ideas

- Add optional Linux comparison notes after the Windows path is complete.
- Add Azure Verified Modules comparison notes where they help learners understand tradeoffs.
- Add cost estimate examples for selected lessons.
- Add guided review questions at the end of each phase.
- Add a release notes workflow for tagged curriculum versions.

## Change Criteria

A new lesson or major change should:

- Teach one clear Azure or Terraform idea.
- Include cleanup guidance.
- Avoid committing real secrets or tenant-specific values.
- Pass Terraform format and validation where backend-free validation is possible.
- Include or update diagrams when the architecture changes.
- Fit the existing lesson naming and folder structure.
