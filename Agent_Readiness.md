# AI Agent Readiness Assessment

Updated: July 11, 2026

This repo is in decent shape for AI-assisted maintenance, especially for simple conference data updates. It is more agent-ready than the previous assessment because the repo now has a top-level `AGENTS.md` with project context, safe edit zones, data rules, validation guidance, and maintainer-approval boundaries.

The main remaining weakness is that most guardrails are still documented in prose instead of enforced by automated validation. Agents can follow the rules, but the repo does not yet reliably catch mistakes before review.

## Current Readiness

**AI-assisted edits:** 8/10

**Autonomous agent workflows:** 6/10

The project has a simple Jekyll structure, clear conference data files, a root agent instruction file, a conference data validator, documented CI/deploy ownership, and useful contributor documentation. Autonomous workflows still need CI integration for the validator and better documentation for maintenance scripts.

## What Already Helps Agents

- `AGENTS.md` is now the strongest agent-facing file. It explains the project map, safe edit zones, conference data rules, source-of-truth policy, local commands, validation checklist, common tasks, and changes that need maintainer approval.
- `README.md` explains the project, `_data` files, ordering rules, required conference fields, eligibility, and deployment versioning.
- `README.md` now documents the current deployment split: GitHub Pages deploys from `main`, GitHub Actions handles the version/tag release flow, and CircleCI handles build/htmlproofer validation.
- `CONTRIBUTING.md` gives contributor workflows for adding conferences, reporting issues, and page/navigation changes.
- `SETUP.md` provides Docker setup instructions.
- `.github/copilot-instructions.md` now delegates repo-wide policy to `AGENTS.md` and keeps only Copilot-specific reminders.
- `.github/pull_request_template.md` provides a checklist for conference PRs.
- `CODEOWNERS` assigns review ownership.
- `Gemfile`, `docker-compose.yml`, and `devops/setup.sh` make it clear this is a Ruby/Jekyll/GitHub Pages site.
- `tools/validate_data.rb` provides a machine-checkable conference data validator for the YAML data files.
- `.circleci/config.yml` documents the build and htmlproofer validation commands used by CircleCI.
- `ROADMAP.md` now tracks the remaining agent-readiness work, quality metrics work, validation work, and developer-experience improvements.
- `tools/` contains maintenance scripts, especially `tools/identify_updates.rb`, though these scripts are not yet documented.

## Main Gaps

- The conference data validator exists, but it is not yet wired into CI.
- There is no obvious pull request validation workflow owned by GitHub Actions. CircleCI performs build validation, but the validator is not yet part of that validation.
- The CI/deploy story still has one confusing implementation detail: `.github/workflows/deploy.yml` includes Pages artifact upload/deploy steps even though repository settings deploy Pages from the `main` branch.
- Formatting guidance is partial. The repo has `.prettierrc`, but there is no `package.json`, documented Prettier command, ESLint config, `.editorconfig`, or Ruby lint config.
- Issue templates now exist with site-version fields, but there is not yet any automation that aggregates issues by version.
- The maintenance scripts are still undiscoverable. `tools/identify_updates.rb`, `tools/monthly_data.rb`, and `tools/status_find.rb` are not mentioned in README, CONTRIBUTING, SETUP, or `AGENTS.md`.
- Local verification is partly fragile. Docker is documented, but the non-Docker Ruby/gem path can fail if the local environment is not prepared.
- Generated-file guidance exists in `AGENTS.md`, `README.md`, and `CONTRIBUTING.md`.
- The source-of-truth policy for conference updates exists in `AGENTS.md`, `README.md`, and `CONTRIBUTING.md`.

## Recommended Next Additions

1. Simplify or rename `.github/workflows/deploy.yml` so the workflow implementation matches the confirmed deployment model.
   - Keep the version increment and tag behavior if still wanted.
   - Remove or explain the Pages artifact/deploy steps if production deploys from `main`.
2. Add the conference data validator to PR validation.
   - `ruby tools/validate_data.rb`.
3. Add or document PR validation expectations.
   - CircleCI build.
   - Jekyll build.
   - htmlproofer.
4. Document the `tools/` scripts or remove/replace the ones that are no longer part of the workflow.
5. Add documented formatting commands for Prettier, and either add ESLint intentionally or stop referring to ESLint as expected tooling.
6. Add automation or reporting that connects issue-template site-version data to the quality ledger.
7. Make local verification docs clearer for both Docker and non-Docker setups.

## Current Bottom Line

The repo is now ready for supervised AI agents to make narrow, reviewable changes such as adding, updating, moving, or closing conference entries.

It is not yet ready for broad autonomous maintenance because the most important rules are still human-readable instructions rather than executable checks.
