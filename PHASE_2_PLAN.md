## Phase 2 Plan: Quality Ledger & Metrics

### Summary
- Implement Phase 2 on branch `codex/phase-2-quality-ledger`.
- Capture one quality snapshot per release tag (`vNNNN`) with Lighthouse, broken-link count, and build time.
- Persist snapshots in-repo for future dashboarding, while preventing metrics commits from triggering deploy/version loops.
- Add an issue template field for `Site Version` so bug reports can be attributed to releases.

### Implementation Changes
- Update deploy workflow in `.github/workflows/deploy.yml`:
  - Move tag creation to after the Pages deploy step so a tag represents an already-deployed version.
  - Add `paths-ignore` for the quality ledger file(s) so metrics-only commits do not trigger deploy/version bump.
- Add a new workflow (for example `.github/workflows/quality-ledger.yml`) that runs on tag pushes matching `v*` and on manual dispatch:
  - Read version from the tag.
  - Run `bundle exec jekyll build` and record elapsed seconds.
  - Serve `_site` locally and run Lighthouse audits; capture Performance, Accessibility, and SEO.
  - Run `linkinator` against the built/served site and capture broken-link count.
  - Append a new record to `_data/quality_log.yml` with: `version`, `release_date`, `commit_sha`, `lighthouse.performance`, `lighthouse.accessibility`, `lighthouse.seo`, `broken_links`, `build_time_seconds`, `workflow_run_url`.
  - Commit the updated ledger back to `main` with a bot commit message.
- Add/enable issue templates:
  - Create `.github/ISSUE_TEMPLATE/bug_report.yml` with required `site_version` field and helper text to copy from footer (`rev.XXXX`).
  - Add `.github/ISSUE_TEMPLATE/config.yml` (disable blank issues if desired) and direct bug reporters to include version.
- Documentation updates:
  - Update `README.md` with “Quality Ledger” behavior and where the data lives.
  - Mark Phase 2 checklist progress in `ROADMAP.md` as each item lands.

### Public Interfaces / Data Contract
- New data contract in `_data/quality_log.yml`: one entry per released version with stable keys listed above.
- New contributor-facing interface: GitHub bug issue form with required `Site Version`.
- CI contract: release tags (`vNNNN`) become the trigger for quality snapshot collection.

### Test Plan
- Workflow validation:
  - Run `quality-ledger` via `workflow_dispatch` once to verify parsing/output and ledger append format.
  - Push/create a test tag in a safe branch/repo context to confirm tag-trigger behavior.
- Data validation:
  - Ensure new ledger entry is appended (not overwritten) and version key matches tag.
  - Confirm numeric parsing for Lighthouse scores, broken links, and build seconds.
- Regression checks:
  - Confirm metrics-only ledger commit does not trigger deploy workflow.
  - Confirm normal content changes still trigger deploy and version bump.
- Issue template checks:
  - Open “New issue” UI and verify `site_version` is required and guidance text is present.

### Assumptions & Defaults
- Defaulted storage choice: in-repo ledger at `_data/quality_log.yml` (chosen to support Phase 4 dashboarding).
- Lighthouse target is the locally served built site for repeatable CI numbers; production URL checks can be added later as a secondary metric.
- Bug counts are “attributable” in Phase 2 by collecting `Site Version` in issue intake; aggregate reporting is deferred to Phase 4 dashboard/trends.
