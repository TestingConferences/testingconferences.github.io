# Agent Instructions

This file is the starting point for AI agents working in this repository.

## Project Map

TestingConferences.org is a community-maintained Jekyll site for software testing conferences and workshops.

- `_data/current.yml`: upcoming conferences and workshops.
- `_data/past.yml`: past conferences and workshops, with optional presentation video playlists.
- `_data/closed.yml`: conferences that no longer appear active.
- `_layouts/`, `_includes/`, `_sass/`, `css/`: Jekyll templates and styles.
- `_posts/`, `_drafts/`: news and blog content.
- `tools/`: maintenance scripts.
- `devops/`: local Docker setup and teardown scripts.
- `_site/`: generated Jekyll output. Do not edit this directory.

## CI And Deployment

This repository currently uses GitHub Pages, GitHub Actions, and CircleCI.

- GitHub Pages production is configured to deploy from the `main` branch.
- GitHub Actions is used for the site release flow that appends/increments the site version number and creates tags.
- CircleCI is responsible for build and htmlproofer validation.
- `.github/workflows/deploy.yml` currently includes Pages artifact upload/deploy steps even though repository settings deploy Pages from `main`; treat changes to this workflow as deployment/versioning work that needs maintainer approval.

Relevant files:

- `.github/workflows/deploy.yml`
- `.github/workflows/auto-assign.yml`
- `.circleci/config.yml`

## Safe Edit Zones

For conference data changes, edit only the relevant YAML file in `_data/`.

- Use `_data/current.yml` for upcoming conferences.
- Use `_data/past.yml` for completed conferences.
- Use `_data/closed.yml` for conferences that appear inactive or discontinued.

For site content changes, edit the relevant Markdown, HTML, include, layout, Sass, or config file.

Do not edit generated `_site/` output. Regenerate it with Jekyll instead.

Do not change navigation, deployment, versioning, or ownership behavior unless the task specifically asks for it or a maintainer confirms it.

## Conference Data Rules

Conference entries usually include:

- `name`: full conference name, including the year when applicable.
- `location`: city, region/country, or online.
- `dates`: event dates.
- `url`: official conference URL with `?utm_source=testingconferences`.

Optional fields include:

- `twitter`: handle without the `@` symbol.
- `status`: short registration, CFP, or event status. HTML links are allowed where existing patterns use them.
- `video_playlist`: presentation or talk playlist, for `_data/past.yml` only.
- `first_date` and `last_date`: used by `_data/closed.yml`.

Formatting rules:

- Preserve two-space YAML indentation.
- Preserve chronological display order.
- Quote names or date strings when YAML parsing could be ambiguous, especially names containing `:`.
- Do not include marketing videos as `video_playlist` values.
- Do not include general technology events unless they are specifically focused on software testing, software quality, automation, or a closely related testing community.

## Source Of Truth For Updates

Prefer official conference sources:

- The conference website.
- The organizer's official registration, CFP, or schedule page.
- Official social accounts only when the website is stale or incomplete.

When sources conflict:

- Prefer the most specific official event page over a generic homepage.
- Prefer current-year pages over archived pages.
- Preserve uncertainty in `status` only when it is useful to site visitors.
- Do not invent dates, locations, prices, CFP deadlines, or registration status.

## Local Commands

Docker is the preferred local setup path:

```bash
./devops/setup.sh
./devops/teardown.sh
```

Non-Docker build commands:

```bash
bundle install
ruby tools/validate_data.rb
bundle exec jekyll build --verbose
bundle exec htmlproofer ./_site --disable-external --no-enforce-https --allow-missing-href --ignore-urls '/^\\/\\//'
```

If local Ruby or gem setup fails, report the failure clearly instead of editing generated files by hand.

## Validation Checklist

Before finishing a change, check:

- YAML parses correctly.
- `ruby tools/validate_data.rb` passes.
- Jekyll builds successfully when the environment supports it.
- Conference URLs include `utm_source=testingconferences` where appropriate.
- `twitter` values do not include `@`.
- New or moved conferences are in the correct data file and display order.
- Generated `_site/` files are not included in the change.

## Common Tasks

Adding a conference:

1. Check whether the conference already exists.
2. Add it to `_data/current.yml` in chronological order.
3. Use the official event URL and include the tracking parameter.
4. Add status only when it is useful and supported by the source.

Moving a conference to past:

1. Remove it from `_data/current.yml`.
2. Add it to `_data/past.yml` in the correct order.
3. Add `video_playlist` only for conference talks or presentations.

Marking a conference closed:

1. Confirm the event appears discontinued or inactive.
2. Move or add it to `_data/closed.yml`.
3. Include `first_date` and `last_date` when known.

Updating site pages:

- Do not add pages to `_includes/nav.html` without maintainer confirmation.
- Add discoverable pages to `_includes/footer.html` when appropriate.

## Maintainer Approval Needed

Ask before changing:

- CI or deployment behavior.
- Versioning and tagging behavior.
- Navigation structure.
- Conference eligibility rules.
- Large formatting rewrites.
- Dependency versions.
