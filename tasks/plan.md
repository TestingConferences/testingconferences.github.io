# Implementation Plan: Newsletter Draft Generator

Source spec: `SPEC-newsletter-generator.md`

## Overview

Build a standard-library Ruby CLI that reads `_data/current.yml` and generates a
deterministic Markdown newsletter draft. The draft follows newsletter issue 101:
three event months beginning with `--month`, then all upcoming active discounts,
then all upcoming open CFPs. The implementation remains provider-neutral and never
uploads, schedules, or sends email.

## Architecture Decisions

- Keep V1 in `tools/newsletter.rb`, guarded by
  `if $PROGRAM_NAME == __FILE__`, so tests can require its parsing and rendering
  functions without executing the CLI.
- Use only Ruby standard-library components already available to the project:
  `Date`, `YAML`, `OptionParser`, `CGI`, `FileUtils`, and `Tempfile`.
- Keep newsletter date parsing local rather than refactoring the existing validator.
  The formats must match the validator, but changing the validator would expand the
  risk and scope of this feature.
- Treat the requested month as the deterministic reference point. Do not use
  `Date.today`; this makes historic regeneration byte-identical.
- Represent a parsed event as a small immutable value carrying its source mapping,
  start date, and end date. Rendering operates on those values, while unparseable
  mappings remain available for the review checklist.
- Convert supported `<a href="…">text</a>` source status fragments to Markdown,
  strip other markup, decode HTML entities, and escape Markdown-significant source
  text. Never pass arbitrary source HTML into the draft.
- Write through a temporary file in the destination directory and rename it only
  after rendering succeeds, so invalid arguments or data cannot partially overwrite
  an existing draft.
- Keep the generated current issue (`_drafts/2026-11-newsletter.md`) as an example and
  editorial starting point. It remains generated content and must not be mistaken for
  a sent campaign.

## Dependency Graph

```text
month/date parsing
       │
       ├── rolling event-window selection
       │
       └── upcoming-event eligibility
                    │
status conversion and classification
                    │
             Markdown rendering
                    │
          CLI validation and safe write
                    │
       documentation and real draft
                    │
             full verification
```

## Task List

Tasks are tracked in `tasks/todo.md`.

### Phase 1: Selection foundation

- Task 1: Parse target months and conference date ranges, then select and group the
  rolling three-month event window.

### Phase 2: Newsletter semantics

- Task 2: Convert source text safely and classify every upcoming active discount and
  open CFP while excluding explicitly closed states.
- Task 3: Render the complete deterministic Markdown draft and expose the safe CLI
  write path.

### Checkpoint: Complete generator

- Focused tests pass after all three behavior slices.
- A temporary-directory CLI run proves deterministic regeneration and safe failures.

### Phase 3: Editorial workflow

- Task 4: Document generation and review, then generate the November 2026 draft from
  current conference data.

### Phase 4: Completion audit

- Task 5: Run repository validation/build gates and audit every spec requirement and
  final changed file.

## Risks and Mitigations

| Risk | Impact | Mitigation |
|---|---|---|
| Free-form date strings are misinterpreted | High | Accept only formats already supported by the validator; surface every other value for review instead of guessing. |
| Stale status text produces a stale discount or CFP | Medium | Preserve source wording and add an explicit editor verification checklist; never infer deadline state. |
| HTML status fragments break Markdown | Medium | Convert only anchors, strip other tags, decode entities, and test special characters and multiple links. |
| A failed run damages an edited draft | High | Complete parsing/rendering before an atomic same-directory replacement; test that invalid input preserves the prior file. |
| Empty or year-crossing windows produce surprising structure | Medium | Test all three headings, empty-month messages, and November/December/January rollover. |
| The generated draft is treated as send-ready | Medium | Include visible editorial placeholders and a review checklist; documentation states that generation never sends or uploads. |

## Verification Checkpoints

1. After Task 1: date and rolling-window tests pass; no rendering or file writing exists.
2. After Tasks 2–3: the entire focused suite passes and an explicit-output CLI run is
   byte-identical on regeneration.
3. After Task 4: the documented default command produces the current draft and the
   draft visibly follows issue 101's section order.
4. After Task 5: focused tests, validator tests, data validation, Jekyll, htmlproofer,
   diff checks, and scope/secret audits all pass.

## Parallelization

None. The slices share one small CLI contract and are intentionally sequential. This
avoids merging competing parsers or renderers and keeps every RED/GREEN cycle focused.

## Open Questions

None. Newsletter issue 101 resolved the selection and section-order questions.
