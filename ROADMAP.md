# Roadmap: testingconferences.org

## Project Vision
Continue to use TCorg to experiment and learn. I want to track quality metrics automatically. Yes these are indirect quality metrics, but I'd like to see what I can track on the build side and how it works. Then improve upon them later.

## Using This Roadmap

This is the single source of truth for planned project work. Keep goals, status, and useful implementation notes here instead of creating separate phase-plan or readiness files. Detailed operating instructions belong in `AGENTS.md`, contributor guidance belongs in `CONTRIBUTING.md`, and completed implementation details belong with the relevant code or documentation.

---

## Phase 1.5: Agent Readiness
*Goal: Make narrow, supervised AI-assisted changes safe, predictable, and easy to verify.*

The July 2026 readiness assessment found the repository ready for supervised conference-data changes. The remaining work is primarily deployment clarity, maintenance-tool documentation, validator regression coverage, formatting expectations, and reliable local verification.

- [x] **Workflow Simplification**: Simplify or rename `.github/workflows/deploy.yml` so it matches the confirmed model where GitHub Pages deploys from `main`.
- [ ] **Validator Regression Tests**: Add focused fixtures and automated tests for valid data, representative failures, warnings, date parsing, and schema changes.
- [ ] **Branch Protection**: Require the consolidated validation check for `main` and document the expectation.
- [ ] **Contributor Support Cleanup**: Replace the Code of Conduct placeholder and align contributor support text with the issue forms that actually exist.

## Phase 2: Quality Ledger & Metrics
*Goal: Associate every site version with a specific quality snapshot.*

- [ ] **Lighthouse Tracking**: Automate Lighthouse audits during CI and record Performance, Accessibility, and SEO scores per version.
- [ ] **Link Integrity**: Implement a broken link checker (e.g., `linkinator`) to log broken link counts against the current version.
- [ ] **Build Analytics**: Track and log build times to monitor the impact of site growth on CI/CD performance.
- [x] **Bug Attribution**: Update Issue Templates to include a "Site Version" field to track bug counts relative to specific releases.
- [x] **Conference Data Validator**: Add a machine-checkable validator for `_data/current.yml`, `_data/past.yml`, and `_data/closed.yml` covering required fields, allowed fields, duplicate names, chronological ordering, URL tracking parameters, and `twitter` formatting.
- [x] **PR Validation**: Add a pull request workflow that runs the conference data validator, Jekyll build, and htmlproofer before merge.

### Proposed implementation

- Store one entry per released version in `_data/quality_log.yml`, with stable fields for `version`, `release_date`, `commit_sha`, Lighthouse scores, broken links, build time, and the workflow run URL.
- Collect a snapshot on release tags matching `v*`, with a manual trigger available for testing and recovery.
- Build and serve the site locally in CI so Lighthouse and link checks operate against repeatable output.
- Append rather than overwrite records, and prevent a metrics-only commit from causing a deployment or versioning loop.
- Treat the issue form's Site Version field as the collection mechanism for bug attribution; aggregate reporting belongs in Phase 4.
- Update the README when the ledger exists and validate the workflow manually before relying on tag-triggered collection.

Changes to `.github/workflows/deploy.yml`, release tags, Pages deployment, or versioning require maintainer approval before implementation.

## Phase 3: Developer Experience (DX) & AI Workflows
*Goal: Streamline contributions using automation and AI context.*

- [ ] **Formatting Expectations**: Document a supported Prettier command and intentionally add any further linting or pre-commit tooling only when it fits the repository.
- [x] **AI Contextualization**: Create a `.github/copilot-instructions.md` to help GitHub Copilot understand the conference data schema and project goals.
- [ ] **Prompt Imports**: Build a library of standardized prompts to assist contributors in formatting and validating new conference submissions.
- [ ] **Maintenance Script Documentation**: Document the scripts in `tools/`, especially `tools/identify_updates.rb`, `tools/monthly_data.rb`, and `tools/status_find.rb`, or remove/replace scripts that are no longer part of the workflow.
- [ ] **Local Verification Docs**: Make the local build and validation paths reliable and clear for both Docker and non-Docker setups.

## Phase 3.5: Newsletter Generation & Platform Migration
*Goal: Reduce the work required to publish the monthly newsletter while preserving editorial review and subscriber consent.*

### Platform-neutral draft generator

- [ ] **Define the Newsletter Format**: Document the recurring sections, selection rules, tone, subject-line pattern, and optional editorial or sponsor content using representative past issues.
- [ ] **Replace the Monthly Data Prototype**: Upgrade or replace `tools/monthly_data.rb` with a non-interactive command that accepts a target month such as `--month 2026-09`.
- [ ] **Generate Markdown**: Read `_data/current.yml`, select the relevant conferences, and render a polished Markdown draft rather than raw YAML.
- [ ] **Highlight Timely Information**: Group supported CFP, registration, and early-bird information without inventing details that are absent from the conference data.
- [ ] **Support Editorial Review**: Include clearly marked areas for an introduction, sponsor copy, announcements, and final notes.
- [ ] **Keep Drafts Reviewable**: Store generated drafts in a predictable, version-controlled location and make repeated generation deterministic.
- [ ] **Add Focused Tests**: Cover month selection, chronological order, missing or ambiguous dates, escaping, links, and empty-month behavior.
- [ ] **Document the Workflow**: Add the local command, expected output, review checklist, and troubleshooting guidance.

### Buttondown trial

- [ ] **Evaluate Against Requirements**: Confirm current pricing for the active subscriber count, sending-domain support, archives, analytics, surveys, and any required add-ons.
- [ ] **Create a Test Newsletter**: Configure Buttondown without changing the production subscription form or disabling Mailchimp.
- [ ] **Verify Markdown Rendering**: Import a representative generated issue and check desktop, mobile, plain-text, links, reply-to behavior, and unsubscribe flow.
- [ ] **Prototype Draft Upload**: Add an optional command that creates a Buttondown email with `status: draft` through the API.
- [ ] **Protect Credentials**: Supply `BUTTONDOWN_API_KEY` through the supported secret store or environment and never commit it.
- [ ] **Require Human Sending**: Keep final scheduling and sending manual until the workflow has demonstrated that it is safe; draft generation or upload must never send automatically.

### Mailchimp migration and cutover

- [ ] **Export and Back Up Mailchimp**: Export subscribed contacts, unsubscribe/suppression history, audience fields, and campaign archives before making changes.
- [ ] **Import Into Buttondown**: Use Buttondown's Mailchimp migration process and wait for its migration audit to complete.
- [ ] **Reconcile the Migration**: Compare active subscriber totals, unsubscribed contacts, metadata, and archives; ensure opted-out contacts cannot be mailed.
- [ ] **Authenticate Sending**: Configure and verify the sending domain, sender identity, reply-to address, and test delivery before production use.
- [ ] **Update the Website**: Replace the Mailchimp form and disclosure in `subscribe.html`, then update Mailchimp links in the footer, README, and relevant pages.
- [ ] **Test Subscription Flows**: Verify new signup, confirmation, duplicate signup, invalid address, unsubscribe, and optional unsubscribe-feedback behavior.
- [ ] **Run a Controlled First Send**: Send test copies, review the final draft, and use Buttondown for one production issue while Mailchimp remains available for rollback.
- [ ] **Retire Mailchimp**: Disable Mailchimp only after the first Buttondown issue and new subscriber flow are confirmed; retain required suppression and consent records.

### Possible later automation

- [ ] **Manual CI Trigger**: Consider a `workflow_dispatch` action that generates or uploads a draft without sending it.
- [ ] **Change-aware Sections**: Explore identifying newly added or materially updated conferences from Git history instead of adding tracking fields prematurely.
- [ ] **Feedback Reporting**: Aggregate voluntary unsubscribe-survey responses and newsletter performance trends without contacting opted-out subscribers.

References:

- [Buttondown's Mailchimp migration guide](https://docs.buttondown.com/mailchimp)
- [Buttondown API draft workflow](https://docs.buttondown.com/drafting-emails-via-the-api)
- [Buttondown embedded subscription forms](https://docs.buttondown.com/building-your-subscriber-base)

## Phase 4: Public Quality Dashboard
*Goal: Surface project health and transparency to the community.*

- [ ] **Metrics Dashboard**: Build a public-facing page (e.g., `/stats` or `/quality`) to visualize project health.
- [ ] **Trend Visualization**: Display historical graphs of Lighthouse scores, bug counts, and conference growth over different versions.
- [ ] **Live Status Badges**: Integrate dynamic README badges for current version, build status, and site health.
- [ ] **Bug Trend Reporting**: Aggregate issue-template Site Version data so bug counts can be compared across releases.

## Miscellaneous
*Goal: Track useful ideas that do not yet belong to a larger phase.*

- [ ] **Calendar Download**: Make the current TC.org data available as an ICS calendar import.
- [ ] **Reference License in Footer**: Should we reference our MIT-LICENSE file in super footer?
- [ ] **Broader Test Coverage**: Add automated tests beyond the conference-data validator where they protect meaningful behavior.

---
*Last Updated: August 2026*
