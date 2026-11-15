# Newsletter Draft Generator Tasks

Source spec: `SPEC-newsletter-generator.md`

Implementation plan: `tasks/plan.md`

## Task 1: Select the rolling three-month conference window

**Description:** Add focused tests first, then implement strict target-month parsing,
supported conference date-range parsing, chronological ordering, year rollover, and
month grouping without reading the system clock.

**Acceptance criteria:**

- [x] `YYYY-MM` input is required and invalid values fail with useful messages.
- [x] Single-day, same-month, cross-month, abbreviated-month, and reversed day/month
      source formats produce correct start and end dates.
- [x] Events whose start dates fall within the rolling three-month window are grouped
      by start month and ordered by start date then name.
- [x] Ambiguous or unparseable dates are never guessed and remain available for review.

**Verification:**

- [x] RED: `ruby test/newsletter_test.rb` fails for the missing selection behavior.
- [x] GREEN: `ruby test/newsletter_test.rb` passes for selection tests.
- [x] `ruby test/validate_data_test.rb` still passes.

**Dependencies:** None

**Files likely touched:**

- `tools/newsletter.rb`
- `test/newsletter_test.rb`
- `test/fixtures/newsletter/current.yml`

**Estimated scope:** Medium (3 files)

## Task 2: Classify discounts and CFPs safely

**Description:** Add tests first, then convert supported source status HTML to safe
Markdown and select all upcoming active discounts and open CFPs outside the three-month
event window while retaining ordinary registration status only on event entries.

**Acceptance criteria:**

- [ ] Anchor tags become Markdown links; unsupported HTML becomes readable plain text.
- [ ] Markdown-significant source text is escaped without changing URLs.
- [ ] Every parseable upcoming event with an active discount status is selected.
- [ ] Every parseable upcoming event with an explicitly open CFP is selected.
- [ ] Closed, ended, expired, or sold-out discounts and closed CFPs are excluded.
- [ ] Ordinary registration alone does not place an event in either global list.

**Verification:**

- [ ] RED: focused status tests fail before implementation.
- [ ] GREEN: `ruby test/newsletter_test.rb` passes after implementation.

**Dependencies:** Task 1

**Files likely touched:**

- `tools/newsletter.rb`
- `test/newsletter_test.rb`
- `test/fixtures/newsletter/current.yml`

**Estimated scope:** Medium (3 files)

## Task 3: Render and write the deterministic draft

**Description:** Add rendering and command-level tests first, then produce the complete
Markdown format, visible editorial placeholders, review checklist, empty-month output,
CLI options, and atomic destination replacement.

**Acceptance criteria:**

- [ ] Output follows the approved section order and contains all four editorial areas.
- [ ] Three monthly sections always appear, including explicit empty-month messages.
- [ ] Suggested subject/preheader and all generated copy are deterministic.
- [ ] Unparseable event names appear in the review checklist.
- [ ] Default output is `_drafts/YYYY-MM-newsletter.md`; `--output` is supported.
- [ ] Repeated generation from unchanged data is byte-identical.
- [ ] Invalid input/data exits nonzero without partially overwriting an existing file.

**Verification:**

- [ ] RED: rendering/CLI tests fail before implementation.
- [ ] GREEN: `ruby test/newsletter_test.rb` passes.
- [ ] Two explicit-output runs have identical checksums.

**Dependencies:** Tasks 1–2

**Files likely touched:**

- `tools/newsletter.rb`
- `test/newsletter_test.rb`

**Estimated scope:** Small (2 files)

## Checkpoint: Complete generator

- [ ] `ruby test/newsletter_test.rb` passes with no skipped tests.
- [ ] `ruby test/validate_data_test.rb` passes.
- [ ] Manual CLI checks confirm success and safe failure behavior.
- [ ] Tasks 1–3 are committed as reviewable save points.

## Task 4: Document and generate the editorial draft

**Description:** Document the local command, expected structure, editor checklist,
regeneration behavior, and troubleshooting, then run the default command for November
2026 and inspect the resulting Markdown against newsletter issue 101.

**Acceptance criteria:**

- [ ] `docs/newsletter-workflow.md` explains generation, review, regeneration, and
      troubleshooting without promising upload or send behavior.
- [ ] `_drafts/2026-11-newsletter.md` is generated solely from current repository data.
- [ ] The draft contains November 2026, December 2026, and January 2027 sections,
      followed by all upcoming discounts and all open CFPs.
- [ ] The draft visibly retains placeholders for introduction, sponsor copy,
      announcements, and final notes.

**Verification:**

- [ ] Run `ruby tools/newsletter.rb --month 2026-11`.
- [ ] Re-run it and confirm no diff in the generated draft.
- [ ] Review the generated section order and checklist manually.

**Dependencies:** Task 3

**Files likely touched:**

- `docs/newsletter-workflow.md`
- `_drafts/2026-11-newsletter.md`

**Estimated scope:** Small (2 files)

## Task 5: Run the completion audit

**Description:** Run every focused and repository gate, then audit the final diff
against the approved spec and repository safety rules.

**Acceptance criteria:**

- [ ] Focused tests and existing validator regression tests pass.
- [ ] Production conference data validation passes.
- [ ] Jekyll and htmlproofer pass when the local environment supports them.
- [ ] No `_site`, conference data, credential, provider, navigation, CI, deployment,
      versioning, dependency, or unrelated files are included.
- [ ] Every success criterion in `SPEC-newsletter-generator.md` has direct evidence.

**Verification:**

- [ ] `ruby test/newsletter_test.rb`
- [ ] `ruby tools/validate_data.rb`
- [ ] `ruby test/validate_data_test.rb`
- [ ] `bundle exec jekyll build --verbose`
- [ ] `bundle exec htmlproofer ./_site --disable-external --no-enforce-https --allow-missing-href --ignore-urls '/^\/\//'`
- [ ] `git diff --check`
- [ ] Final status/diff and sensitive-filename/content review

**Dependencies:** Tasks 1–4

**Files likely touched:** None beyond task/checklist completion marks

**Estimated scope:** Extra small (verification only)

## Checkpoint: Complete

- [ ] All task acceptance criteria and verification items are checked.
- [ ] All approved spec success criteria are proven.
- [ ] Final changes are ready for maintainer review.
