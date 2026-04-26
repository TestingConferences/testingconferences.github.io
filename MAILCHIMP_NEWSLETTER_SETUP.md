# Mailchimp Newsletter Setup

This guide gets you from zero to a draft Mailchimp campaign populated with conference data from this repo.

## 1) Create Mailchimp API credentials

1. In Mailchimp, open `Account -> Extras -> API keys`.
2. Create a new API key.
3. Copy the key value (it should end with a datacenter suffix like `-us6`).

## 2) Choose your source campaign

1. Open an existing Mailchimp campaign that has the format you want.
2. Copy its campaign ID.
3. Add this placeholder to the campaign HTML where event content should go:
   - `{{TESTING_CONFERENCES_CONTENT}}`

If the placeholder is missing, the script appends the generated event block near the end of the email.

## 3) Configure local secrets

1. Copy `.env.example` to `.env`.
2. Set the values in `.env`:

```dotenv
MAILCHIMP_API_KEY=your_key-usX
MAILCHIMP_SOURCE_CAMPAIGN_ID=your_campaign_id
```

## 4) Preview newsletter content

Run a dry run first:

```bash
ruby tools/mailchimp_replicate_newsletter.rb --dry-run --limit 5
```

This generates HTML from `_data/current.yml` and prints it locally without calling Mailchimp.

## 5) Create a draft in Mailchimp

```bash
ruby tools/mailchimp_replicate_newsletter.rb --subject "Testing Conferences: Monthly Update"
```

What this does:

1. Replicates your source campaign format.
2. Filters upcoming events from `_data/current.yml` (default: next 60 days).
3. Replaces `{{TESTING_CONFERENCES_CONTENT}}` with generated event HTML.
4. Updates title (and subject if provided).

## 6) Review and send

1. Open the new draft in Mailchimp.
2. Verify formatting and links.
3. Send a test email.
4. Schedule or send.

## Useful options

```bash
# Include up to 12 events (default)
ruby tools/mailchimp_replicate_newsletter.rb --limit 12

# Change date window (default 60 days)
ruby tools/mailchimp_replicate_newsletter.rb --days-ahead 45

# Use a custom placeholder token
ruby tools/mailchimp_replicate_newsletter.rb --placeholder "{{MY_EVENTS_BLOCK}}"
```

## Troubleshooting

1. `MAILCHIMP_API_KEY is required`:
   - Check `.env` exists in repo root and key name is exact.
2. `MAILCHIMP_SOURCE_CAMPAIGN_ID is required`:
   - Add the campaign ID to `.env` or pass `--source-campaign`.
3. `No upcoming events found`:
   - Increase `--days-ahead` or verify event dates in `_data/current.yml`.
