# AI Agent Readiness Assessment

Updated: June 28, 2026

This repo is in decent shape for AI-assisted maintenance, especially for simple conference data updates. It is more agent-ready than the previous assessment because the repo now has a top-level `AGENTS.md` with project context, safe edit zones, data rules, validation guidance, and maintainer-approval boundaries.

The main remaining weakness is that most guardrails are still documented in prose instead of enforced by automated validation. Agents can follow the rules, but the repo does not yet reliably catch mistakes before review.

## Current Readiness

**AI-assisted edits:** 7/10

**Autonomous agent workflows:** 5/10

The project has a simple Jekyll structure, clear conference data files, a root agent instruction file, and useful contributor documentation. Autonomous workflows still need stronger machine-checkable validation, clearer CI/deploy documentation, and better documentation for maintenance scripts.

## What Already Helps Agents

- `AGENTS.md` is now the strongest agent-facing file. It explains the project map, safe edit zones, conference data rules, source-of-truth policy, local commands, validation checklist, common tasks, and changes that need maintainer approval.
- `README.md` explains the project, `_data` files, ordering rules, required conference fields, eligibility, and deployment versioning.
- `README.md` now documents the current CI split: GitHub Actions is used for the site release-flow version increment, while CircleCI still handles build validation and site deployment.
- `CONTRIBUTING.md` gives contributor workflows for adding conferences, reporting issues, and page/navigation changes.
- `SETUP.md` provides Docker setup instructions.
- `.github/copilot-instructions.md` now delegates repo-wide policy to `AGENTS.md` and keeps only Copilot-specific reminders.
- `.github/pull_request_template.md` provides a checklist for conference PRs.
- `CODEOWNERS` assigns review ownership.
- `Gemfile`, `docker-compose.yml`, and `devops/setup.sh` make it clear this is a Ruby/Jekyll/GitHub Pages site.
- `.circleci/config.yml` documents the build and htmlproofer validation commands used by CircleCI.
- `ROADMAP.md` now tracks the remaining agent-readiness work, quality metrics work, validation work, and developer-experience improvements.
- `tools/` contains maintenance scripts, especially `tools/identify_updates.rb`, though these scripts are not yet documented.

## Main Gaps

- There is still no machine-checkable data schema or validator for `_data/current.yml`, `_data/past.yml`, or `_data/closed.yml`. The schema is documented in prose, but agents would be safer with a YAML/JSON schema or validator.
- There is no obvious pull request validation workflow owned by GitHub Actions. CircleCI performs build validation, but the repo should make the current source of truth unmistakable to agents and contributors.
- The CI/deploy story can still confuse agents. `.github/workflows/deploy.yml` appears to build and deploy GitHub Pages, while the current documented operating model says GitHub Actions is only for release-flow version incrementing and CircleCI handles build validation and deployment.
- There is no automated linting despite `CONTRIBUTING.md` mentioning Prettier/ESLint. There is no `package.json`, lint config, `.editorconfig`, or Ruby lint config.
- There are no issue templates, despite the roadmap calling out bug attribution and site version tracking.
- The maintenance scripts are still undiscoverable. `tools/identify_updates.rb`, `tools/monthly_data.rb`, and `tools/status_find.rb` are not mentioned in README, CONTRIBUTING, SETUP, or `AGENTS.md`.
- Local verification is partly fragile. Docker is documented, but the non-Docker Ruby/gem path can fail if the local environment is not prepared.
- Generated-file guidance now exists in `AGENTS.md`, but it is not yet repeated in contributor-facing docs.
- The source-of-truth policy for conference updates now exists in `AGENTS.md`, but it is not yet repeated in contributor-facing docs.

## Recommended Next Additions

1. Add a conference data validator for `_data/current.yml`, `_data/past.yml`, and `_data/closed.yml`.
   - Required fields.
   - Allowed fields.
   - Duplicate conference names.
   - Chronological ordering.
   - Required `utm_source=testingconferences` on conference URLs.
   - No `@` in `twitter`.
   - `_data/closed.yml` support for `first_date` and `last_date`.
2. Clarify CI/deploy ownership in one place and make workflow names match reality.
   - If CircleCI is the build/deploy source of truth, document that in README, `AGENTS.md`, and Copilot instructions.
   - Rename or revise GitHub Actions workflow language if it is only responsible for version incrementing.
3. Add or document PR validation expectations.
   - CircleCI build.
   - Jekyll build.
   - htmlproofer.
   - Future conference data validator.
4. Document the `tools/` scripts or remove/replace the ones that are no longer part of the workflow.
5. Add issue templates with a site-version field.
6. Make local verification docs clearer for both Docker and non-Docker setups.

## Current Bottom Line

The repo is now ready for supervised AI agents to make narrow, reviewable changes such as adding, updating, moving, or closing conference entries.

It is not yet ready for broad autonomous maintenance because the most important rules are still human-readable instructions rather than executable checks.
