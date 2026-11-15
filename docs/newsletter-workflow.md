# Newsletter draft workflow

The newsletter generator turns `_data/current.yml` into a reviewable Markdown draft.
It does not connect to an email provider, upload a campaign, schedule a message, or
send email.

## Generate a draft

Pass the first month of the issue in `YYYY-MM` form:

```bash
ruby tools/newsletter.rb --month 2026-11
```

The command writes `_drafts/2026-11-newsletter.md`. It does not prompt for input, so
the same command can be repeated during editorial review.

To inspect output without replacing the default draft, provide another path:

```bash
ruby tools/newsletter.rb --month 2026-11 --output /tmp/2026-11-newsletter.md
```

Generation is deterministic: unchanged conference data and the same target month
produce byte-identical Markdown. Re-running the command replaces the exact output
file, including any manual edits in that file. Make conference-data corrections before
regenerating, or write to a temporary path and merge the changes into an edited draft.

## What the generator selects

The issue format follows newsletter #101:

1. Three conference months beginning with `--month`. Events are selected and grouped
   by their start date, then ordered chronologically within each month.
2. Every parseable upcoming event whose status identifies an active discount, including
   early-bird, super-early-bird, blind-bird, blind-registration, and similar offers.
3. Every parseable upcoming event whose status explicitly identifies an open CFP, call
   for proposals, call for papers, or call for speakers.

Ordinary registration status appears with an event in the three-month conference
calendar. It does not create a separate all-registration list.

The generator copies facts and status wording from `_data/current.yml`. It does not
decide whether a listed deadline has passed or whether an organizer's page has changed.
An ambiguous or missing event date is not guessed; the event is named in the draft's
review checklist instead.

## Review before using the draft

The generated Markdown is an editorial starting point. Before importing it into an
email provider:

1. Replace the introduction and final-notes placeholders.
2. Add approved sponsor copy or remove the sponsor section.
3. Add announcements or remove that section.
4. Review the suggested subject and preheader.
5. Resolve or intentionally omit every event named for an ambiguous or missing date.
6. Verify conference dates, locations, registration states, discounts, CFPs, and
   deadlines against official event sources.
7. Open every link.
8. Review the final campaign on desktop and mobile and check its plain-text version.
9. Send a provider test message before scheduling or sending the production issue.

Provider actions remain manual and outside this command.

## Troubleshooting

### `Missing required option: --month YYYY-MM`

Include a target month:

```bash
ruby tools/newsletter.rb --month 2026-11
```

The month must contain a four-digit year and a two-digit calendar month. Values such
as `2026-1`, `2026-13`, and `November 2026` are rejected.

### Conference data cannot be read

Run the repository validator first:

```bash
ruby tools/validate_data.rb
```

Correct YAML syntax and required-field errors in `_data/current.yml`, then generate
the draft again. The generator completes parsing and rendering before replacing the
output file, so invalid input does not partially overwrite an existing draft.

### A conference is missing from the three-month calendar

Confirm that its `dates` value has a supported date and that its start month is inside
the three-month window. A cross-month event appears under its start month. Ambiguous
values such as `2027 TBA` appear in the review checklist instead of the calendar.

### A discount or CFP is missing

Check the event's `status` in `_data/current.yml`. Discounts need recognizable active
discount language. CFPs need both a CFP/call-for-proposals term and an explicit open
state. Statuses marked closed, ended, expired, or sold out are excluded unless the same
status also describes another supported active offer.

### A month has no conferences

This is valid. The generator keeps all three month headings and writes an explicit
no-events message so the editor can decide whether to retain that month in the final
campaign.
