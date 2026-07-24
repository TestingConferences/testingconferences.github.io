# AI Agent Readiness Assessment

Updated: July 11, 2026

This repo is in decent shape for AI-assisted maintenance, especially for simple conference data updates. It is more agent-ready than the previous assessment because the repo now has a top-level `AGENTS.md` with project context, safe edit zones, data rules, validation guidance, and maintainer-approval boundaries.

The conference-data validator makes important guardrails executable and is enforced in CI on pull requests and pushes to `main`. The remaining weaknesses are concentrated in deployment clarity, undocumented maintenance scripts, validator regression coverage, and developer-tooling expectations that still exist only in prose.

## Current Readiness

**AI-assisted edits:** 8/10

**Autonomous agent workflows:** 7/10

The project has a simple Jekyll structure, clear conference data files, a root agent instruction file, a conference data validator enforced in CI, documented CI/deploy ownership, and useful contributor documentation. Autonomous workflows still need better documentation for maintenance scripts and clearer formatting automation.

## What Already Helps Agents

- `AGENTS.md` is now the strongest agent-facing file. It explains the project map, safe edit zones, conference data rules, source-of-truth policy, local commands, validation checklist, common tasks, and changes that need maintainer approval.
- `README.md` explains the project, `_data` files, ordering rules, required conference fields, eligibility, and deployment versioning.
- `README.md` now documents the current deployment model: GitHub Pages deploys from `main`, while GitHub Actions handles conference data validation, the Jekyll build, htmlproofer, and the version/tag release flow.
- `CONTRIBUTING.md` gives contributor workflows for adding conferences, reporting issues, and page/navigation changes.
- `SETUP.md` provides Docker setup instructions.
- `.github/copilot-instructions.md` now delegates repo-wide policy to `AGENTS.md` and keeps only Copilot-specific reminders.
- `.github/pull_request_template.md` provides a checklist for conference PRs.
- `CODEOWNERS` assigns review ownership.
- `Gemfile`, `docker-compose.yml`, and `devops/setup.sh` make it clear this is a Ruby/Jekyll/GitHub Pages site.
- `tools/validate_data.rb` provides a machine-checkable conference data validator for the YAML data files.
- `.github/workflows/ci.yml` validates pull requests and pushes to `main` with the conference data validator, Jekyll build, and htmlproofer.
- `ROADMAP.md` now tracks the remaining agent-readiness work, quality metrics work, validation work, and developer-experience improvements.
- `tools/` contains maintenance scripts, especially `tools/identify_updates.rb`, though these scripts are not yet documented.

## Main Gaps By Priority

### P1: Critical

No critical gaps remain for supervised conference-data changes.

### P2: Important

- The maintenance scripts have no documented contracts. `tools/identify_updates.rb`, `tools/monthly_data.rb`, and `tools/status_find.rb` are not described in README, CONTRIBUTING, SETUP, or `AGENTS.md`; their inputs, generated files, intended review steps, and destructive/non-destructive behavior must be inferred from source.
- The validator itself has no automated test suite or fixtures. Running it proves it accepts the current data, but does not protect expected failures, warning behavior, date parsing, or schema changes from regression.

### P3: Useful

- The CI/deploy story still has one confusing implementation detail: `.github/workflows/deploy.yml` includes Pages artifact upload/deploy steps even though repository settings deploy Pages from the `main` branch.
- Formatting guidance is partial. The repo has `.prettierrc`, but there is no `package.json`, documented Prettier command, ESLint config, `.editorconfig`, or Ruby lint config.
- Local verification is partly fragile. Docker is documented, but the non-Docker path has no `.ruby-version` or setup troubleshooting, and requires the correct Ruby and locally installed locked gems.
- Issue templates collect site versions, but no automation aggregates issues by version for the quality ledger.
- `CONTRIBUTING.md` refers to a Code of Conduct using placeholder text, and tells users to open a "Question" issue although there is no dedicated question issue form.

## Recommended Next Additions

1. Resolve the deployment/versioning workflow so its implementation matches the confirmed deployment model.
   - Keep the version increment and tag behavior if still wanted.
   - Remove or explain the Pages artifact/deploy steps if production deploys from `main`.
2. Document each maintenance script's purpose, invocation, inputs, outputs, and human review step; remove scripts that are no longer supported.
3. Add focused tests and fixtures for `tools/validate_data.rb`, including valid entries and representative hard failures.
4. Require the consolidated validation check in the `main` branch protection or ruleset, then document that expectation.
5. Add documented formatting commands for Prettier, and either add ESLint intentionally or remove it from the roadmap.
6. Make local verification reliable for both Docker and non-Docker setups, including the expected Ruby version.
7. Replace the Code of Conduct placeholder and align contributor support text with the available issue forms.
8. Add automation or reporting that connects issue-template site-version data to the quality ledger.

## Current Bottom Line

The repo is ready for supervised AI agents to make narrow, reviewable conference changes. GitHub Actions enforces the conference-data validator, Jekyll build, and generated-site checks.

It is not yet ready for broad autonomous maintenance because deployment authority, maintenance-tool contracts, validator regression behavior, and formatting expectations are not fully specified or enforced.
