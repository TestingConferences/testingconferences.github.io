# AI Agent Readiness Assessment

This repo is moderately ready for AI-assisted maintenance, especially for simple conference data edits. It is less ready for reliable autonomous agent workflows because some guidance is stale and several validation steps are documented only in prose.

## Current Readiness

**AI-assisted edits:** 6/10

**Autonomous agent workflows:** 4/10

The project has useful documentation and a simple Jekyll data model, but it needs fresher instructions and executable guardrails before an agent can safely make broader changes without human supervision.

## What Already Helps Agents

- `README.md` explains the project, `_data` files, ordering rules, required conference fields, eligibility, and deployment versioning.
- `CONTRIBUTING.md` gives contributor workflows for adding conferences, reporting issues, and page/navigation changes.
- `SETUP.md` provides simple Docker setup instructions.
- `.github/copilot-instructions.md` is the strongest agent-facing file. It explains repo structure, schema, common tasks, build commands, and contribution rules.
- `.github/pull_request_template.md` provides a checklist for conference PRs.
- `CODEOWNERS` assigns review ownership.
- `Gemfile`, `docker-compose.yml`, and `devops/setup.sh` make it clear this is a Ruby/Jekyll/GitHub Pages site.
- `ROADMAP.md` gives future direction around quality, AI workflows, tests, metrics, and automation.
- `tools/` contains maintenance scripts, especially `tools/identify_updates.rb`, though these scripts are not yet documented.

## Main Gaps

- There is no top-level `AGENTS.md`. Codex-style agents commonly look for this. The Copilot file is helpful, but it is tool-specific and hidden under `.github/`.
- Agent docs are stale in places. `.github/copilot-instructions.md` references `.circleci/`, while the repo currently uses GitHub Actions. The README badge also still points at CircleCI.
- There is no machine-checkable data schema for `_data/current.yml`, `_data/past.yml`, or `_data/closed.yml`. The schema exists in prose, but agents would be safer with a YAML/JSON schema or validator.
- There is no PR validation workflow for builds/tests. The deploy workflow builds on push to `main`, but there is no obvious workflow that validates pull requests before merge.
- There is no automated linting despite `CONTRIBUTING.md` mentioning Prettier/ESLint. There is no `package.json`, lint config, `.editorconfig`, or Ruby lint config.
- There are no issue templates, despite the roadmap calling out bug attribution and site version tracking.
- The maintenance scripts are undiscoverable. `tools/identify_updates.rb`, `tools/monthly_data.rb`, and `tools/status_find.rb` are not mentioned in README, CONTRIBUTING, SETUP, or Copilot instructions.
- Local verification is fragile. `bundle exec jekyll build` can fail if the active Ruby/gem environment is not ready. Docker likely works, but the non-Docker path is underdocumented.
- There is no explicit "do not edit generated files" guidance. `_site/` exists and is ignored, but agent instructions should explicitly say never to modify generated `_site` output.
- There is no source-of-truth policy for conference updates: acceptable sources, how to confirm dates/status, what to do when information conflicts, and whether web research is required.

## Recommended Next Additions

1. Add `AGENTS.md` at the repo root with the real source of truth for agents: project map, safe-edit zones, data schema, commands, validation checklist, and common tasks.
2. Fix stale docs: remove CircleCI references, update badges, mark the `.github/copilot-instructions.md` roadmap item complete, and document GitHub Actions.
3. Add a simple validator script for conference YAML: required fields, URL tracking parameter, duplicate names, chronological ordering, no `@` in `twitter`, and allowed fields.
4. Add a PR CI workflow that runs `bundle exec jekyll build` and the validator.
5. Document the `tools/` scripts or remove/replace the ones that are no longer part of the workflow.

## Useful Agent Instructions To Add Later

An `AGENTS.md` file should answer these questions directly:

- What kind of site is this?
- Which files are source files and which are generated?
- Which files should agents edit for conference changes?
- What fields are required for each YAML data file?
- What command starts the site locally?
- What command validates a change?
- What should an agent do when conference details conflict between sources?
- What should an agent never change without maintainer approval?

