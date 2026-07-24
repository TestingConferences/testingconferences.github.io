# GitHub Copilot Instructions for TestingConferences.org

Follow the repository-wide agent guidance in [`AGENTS.md`](../AGENTS.md) first. `AGENTS.md` is the source of truth for project structure, safe edit zones, conference data rules, CI/deployment notes, validation expectations, source-of-truth policy, and maintainer-approval boundaries.

If this file conflicts with `AGENTS.md`, prefer `AGENTS.md`.

## Copilot-Specific Reminders

- Make small, targeted changes that match the existing file style.
- For conference updates, edit only the relevant file in `_data/`: `current.yml`, `past.yml`, or `closed.yml`.
- Do not edit generated `_site/` output.
- Preserve two-space YAML indentation and existing chronological ordering.
- Include `utm_source=testingconferences` on conference URLs where appropriate.
- Do not include `@` in `twitter` values.
- Use official conference sources for dates, status, CFP, registration, and location details.
- Do not invent missing conference details.
- Do not change CI, deployment, versioning, navigation, dependencies, or conference eligibility rules without maintainer approval.

## Validation

When the local environment supports it, use the build and validation commands documented in `AGENTS.md`.

GitHub Pages production is configured to deploy from `main`. GitHub Actions handles conference data validation, the Jekyll build, htmlproofer, and the version/tag release flow. Do not change CI, deployment, or versioning without maintainer approval.
