---
published: false
---

# Spec: Newsletter Draft Generator — V1

Status: approved 2026-11-14

## Objective

Provide maintainers with a non-interactive Ruby command that turns conference data
from `_data/current.yml` into a deterministic, reviewable monthly newsletter draft.
The command reduces repetitive formatting work while keeping all editorial decisions,
provider uploads, scheduling, and sending under human control.

The generated draft is a starting point, not a finished campaign. It must preserve
source wording and links, identify data that needs review, and never infer facts that
are absent from the conference data.

## Newsletter Format

Each generated `_drafts/YYYY-MM-newsletter.md` file contains, in this order:

1. A title naming the target month and year.
2. A deterministic suggested subject and preheader based on the selected event count.
3. A clearly marked introduction placeholder.
4. A clearly marked sponsor-copy placeholder.
5. Three monthly conference sections beginning with the requested month. Each entry
   includes the linked name, source date text, location, and source status when present.
6. An `Upcoming discounts` section containing every upcoming event whose source status
   identifies an active early-bird, super-early-bird, blind-bird, discount, or similar
   reduced-price offer.
7. An `Open CFPs` section containing every upcoming event whose source status explicitly
   identifies an open call for proposals, papers, or speakers.
8. A clearly marked announcements placeholder.
9. A clearly marked final-notes placeholder.
10. A deterministic link to the live conference list and contribution instructions.
11. A `Review before sending` checklist identifying ambiguous or unparseable source
    dates and reminding the editor to verify generated copy and links.

Editorial placeholders use visible bracketed text and adjacent HTML comments so they
are easy to find and hard to mistake for finished copy. Existing `<a>` elements in a
status are converted to Markdown links. Other HTML is reduced to readable plain text;
the generator does not pass arbitrary source HTML into the Markdown draft.

## Selection Rules

- `--month` is required and must use the exact `YYYY-MM` form.
- The requested month is the first month in a rolling three-calendar-month conference
  window. For example, `--month 2026-10` produces October, November, and December 2026
  conference sections.
- An event appears in the three-month conference window when its parsed start date is
  inside that window. A cross-month event is grouped under its start month.
- Events within each month are ordered by parsed start date, then by name for a
  deterministic tie break. Source YAML order does not determine newsletter order.
- Unparseable or ambiguous dates are not guessed. Those events are excluded from the
  conference window, discount list, and CFP list and are named in the review checklist.
- A month with no selected events still receives its own heading and an explicit
  no-events message.
- `Upcoming discounts` and `Open CFPs` are not limited to the three-month conference
  window. They inspect all parseable upcoming events whose end date is on or after the
  first day of the requested month.
- Discount matching is case-insensitive and includes supported active terms such as
  early bird, super early bird, blind bird, discount, savings, and reduced pricing.
  A status explicitly marked closed, ended, expired, or sold out is excluded.
- CFP matching is case-insensitive and requires both a supported CFP/call-for-proposals,
  papers, or speakers term and an explicit open state. A closed CFP is excluded.
- Ordinary registration status is retained on conference entries in the three-month
  window. It does not create a separate all-registration section.
- Status wording, links, and deadlines are copied only from `_data/current.yml`. A
  listed deadline does not control whether an otherwise active discount or CFP is
  included; the editor must verify that source statuses remain current before sending.

## Commands

Generate or deterministically replace a draft:

```bash
ruby tools/newsletter.rb --month 2026-11
```

Generate to an explicit path for review or testing:

```bash
ruby tools/newsletter.rb --month 2026-11 --output /tmp/2026-11-newsletter.md
```

Run focused tests:

```bash
ruby test/newsletter_test.rb
```

Run existing data validation and its regression suite:

```bash
ruby tools/validate_data.rb
ruby test/validate_data_test.rb
```

Run the relevant site gates when the local Ruby environment supports them:

```bash
bundle exec jekyll build --verbose
bundle exec htmlproofer ./_site --disable-external --no-enforce-https --allow-missing-href --ignore-urls '/^\/\//'
```

## Project Structure

```text
tools/newsletter.rb               CLI entry point and newsletter implementation
test/newsletter_test.rb           focused unit and command-level tests
test/fixtures/newsletter/         isolated conference-data fixtures
_drafts/YYYY-MM-newsletter.md     generated, version-controlled editorial drafts
docs/newsletter-workflow.md       command, review checklist, and troubleshooting
```

The implementation remains a small Ruby script using the standard library and the
repository's existing Minitest convention. V1 does not introduce a provider adapter
or a generalized plugin architecture.

## Code Style

Follow existing Ruby conventions: frozen string literals, two-space indentation,
small named methods, standard-library dependencies, and explicit error messages.
Parsing and rendering are separated so behavior can be tested without invoking a
subprocess or writing into the real `_drafts` directory.

Example public boundary:

```ruby
month = Newsletter::TargetMonth.parse(options.fetch(:month))
events = Newsletter::DataFile.load(options.fetch(:data_file))
draft = Newsletter::Draft.render(month:, events:)
Newsletter::Writer.write(options.fetch(:output), draft)
```

This is illustrative rather than a requirement to create one class per operation;
the implementation should use the smallest structure that keeps parsing and rendering
testable.

## Testing Strategy

Use Minitest and real temporary files; do not mock filesystem or YAML behavior.
Tests must be deterministic and must not read or alter the repository's production
conference data unless explicitly exercising the default CLI path.

Focused coverage includes:

- required and valid `--month YYYY-MM` handling;
- single-day, same-month range, and cross-month range selection;
- rolling three-month selection and month grouping across a year boundary;
- chronological ordering independent of YAML order;
- ambiguous and unparseable dates surfaced for review without guessing;
- HTML-link conversion, Markdown escaping, and safe plain-text fallback;
- all-upcoming discount selection outside the three-month event window;
- all-upcoming open-CFP selection outside the three-month event window;
- exclusion of closed discounts and CFPs;
- ordinary registration status retained only on conference entries;
- missing optional fields;
- empty-month output;
- deterministic regeneration and explicit-output behavior;
- nonzero exit status and useful messages for invalid input or unreadable data.

Every behavior change follows RED → GREEN → REFACTOR. The focused suite runs after
each slice; the validator suite and Jekyll/htmlproofer gates run before completion.

## Boundaries

### Always

- Read conference facts only from `_data/current.yml` or an explicit test data file.
- Preserve source URLs and wording unless converting supported HTML to Markdown/plain
  text.
- Write drafts deterministically and replace only the exact target output file.
- Keep final editorial review and sending manual.
- Keep generated drafts version-controlled and readable without Mailchimp, Buttondown,
  or any other provider.

### Ask first

- Change the newsletter section order or selection rules after this spec is approved.
- Change the output location from `_drafts/YYYY-MM-newsletter.md`.
- Add a gem or another dependency.
- Modify conference data, navigation, CI, deployment, versioning, or ownership files.

### Never

- Upload, schedule, or send a newsletter.
- Access or store provider credentials or subscriber information.
- Invent dates, locations, deadlines, registration states, sponsor copy, or editorial
  prose.
- Edit generated `_site` output.
- Modify unrelated conference records while implementing the generator.

## Success Criteria

- `ruby tools/newsletter.rb --month YYYY-MM` succeeds without prompts and writes the
  documented draft path.
- The generated Markdown follows the approved format and selection rules.
- Re-running the same command against unchanged input produces byte-identical output.
- The focused suite proves rolling three-month selection, chronological order, range
  handling, ambiguous dates, escaping, links, all-upcoming discounts, all-upcoming open
  CFPs, closed-status exclusion, registration display, and empty-month output.
- Invalid arguments and invalid data fail safely without partially overwriting an
  existing draft.
- `ruby test/newsletter_test.rb`, `ruby tools/validate_data.rb`, and
  `ruby test/validate_data_test.rb` pass.
- Jekyll builds and htmlproofer passes when the local environment supports the
  repository's documented commands.
- `docs/newsletter-workflow.md` documents generation, editorial review, deterministic
  regeneration, expected output, and troubleshooting.
- The final diff contains no `_site` files, conference-data edits, credentials,
  provider configuration, CI/deployment changes, or dependency changes.

## Out of Scope (Deferred)

- Mailchimp campaign replication or draft upload; evaluate after one generated issue
  has completed editorial review.
- Buttondown integration or Mailchimp migration.
- Sending, scheduling, subscriber management, analytics, or unsubscribe feedback.
- Automated factual research or enrichment beyond `_data/current.yml`.
- Git-history analysis for newly added or materially changed conferences.
- CI-triggered generation.

## Editorial Reference

The selection and section rules above follow the demonstrated structure of newsletter
issue 101: three event months beginning with the issue month, followed by every upcoming
discount and every open CFP. The archived issue is available at
<https://us11.campaign-archive.com/?u=2a811daec24cc97909dfdf01d&id=c58553fb90>.
