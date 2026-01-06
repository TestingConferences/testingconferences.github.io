# GitHub Copilot Instructions for TestingConferences.org

## Project Overview

TestingConferences.org is a community-driven website that lists software testing conferences and workshops. It's built with Jekyll (Ruby-based static site generator) and deployed as a GitHub Pages site.

## Repository Structure

- `_data/` - Contains YAML files with conference data
  - `current.yml` - Upcoming conferences and workshops
  - `past.yml` - Past conferences with optional video playlists
- `_layouts/` - Jekyll layout templates
- `_includes/` - Reusable Jekyll components
- `_posts/` - Blog posts and news
- `_sass/` - Sass stylesheets
- `devops/` - Docker setup scripts for local development
- `.circleci/` - CI/CD configuration

## Build and Test Commands

### Local Development (Docker)

```bash
# Setup (starts Docker container and opens browser)
./devops/setup.sh

# Teardown (stops Docker container)
./devops/teardown.sh
```

### CI/CD Build (CircleCI)

```bash
# Install dependencies
gem install bundler
bundle install

# Build site
bundle exec jekyll build --verbose

# Test (validates HTML and links)
bundle exec htmlproofer ./_site --check-html --disable-external
```

## Data Schema Guidelines

### Conference Entry Format

When adding or updating conferences in `_data/current.yml` or `_data/past.yml`:

**Required Fields:**

- `name` - Full conference name with year
  - Include abbreviations in parentheses when commonly used
  - Examples: `Automation Guild 2026`, `Workshop on Performance and Reliability (WOPR) 2026`
- `location` - City, state/country, and whether online
- `dates` - Event dates (use quotes if complex format)
- `url` - Conference website with `?utm_source=testingconferences` tracking

**Optional Fields:**

- `twitter` - Twitter handle WITHOUT @ symbol
- `status` - Current status (CFP open/closed, registration status, etc.)
  - Can include HTML links: `<a href="..." target="_blank">Registration is Open</a>`
- `video_playlist` - (past.yml only) Link to conference presentation videos

**Important Rules:**

1. Order in YAML files determines display order - insert events in correct chronological position
2. If conference name contains colon (:), wrap in quotes: `"test:fest 2026"`
3. No marketing videos in video_playlist - only actual presentation/talk recordings
4. Only include conferences specifically focused on software testing

### Example Entry

```yaml
- name: Automation Guild 2026
  location: Online
  dates: "February 9-13, 2026"
  url: https://testguild.com/ag-2026/?utm_source=testingconferences
  twitter: testguilds
  status: <a href="https://testguild.com/register/?utm_source=testingconferences" target="_blank">Registration is Open</a>
```

## Code Style and Conventions

- **YAML Files**: Follow existing indentation (2 spaces)
- **Markdown**: Use standard markdown formatting
- **HTML**: Semantic HTML5, accessibility-friendly
- **Links**: Always add `?utm_source=testingconferences` to conference URLs for tracking
- **External Links**: Use `target="_blank"` when appropriate

## Testing Standards

- Always run `bundle exec htmlproofer` after making changes to validate HTML
- Check that Jekyll builds successfully with `bundle exec jekyll build`
- Test locally with Docker before submitting PRs
- All external links should be valid and not broken

## Contributing Guidelines

### Pull Request Workflow

1. Fork the repository and create a branch from `main`
2. Make changes following the data schema
3. Test locally using Docker setup
4. Ensure CircleCI build passes
5. Submit PR with clear description

### Conference Eligibility

Only include conferences/workshops specifically for software testing. Per the README:

- Focus is a goal - only conferences that are specifically for software testing are listed
- If a conference covers software testing but is not specifically for testers, it is excluded
- Good heuristic: conference name includes "Test", "Testing", "Quality", "Automation", or is otherwise clearly focused on testing (e.g., "Robocon", "Automation Guild")
- Conference describes itself as specifically for software testers

## Common Tasks

### Adding a New Conference

1. Check if conference already exists in `_data/current.yml`
2. Add entry following the data schema above
3. Insert in correct chronological order
4. Include all required fields and relevant optional fields
5. Run local build to test
6. Submit PR

### Moving Conference to Past List

1. Remove entry from `_data/current.yml`
2. Add to `_data/past.yml` in chronological order
3. Optionally add `video_playlist` if available
4. Update status if needed

### Updating Conference Information

1. Locate conference in appropriate YAML file
2. Update relevant fields
3. Ensure format compliance
4. Test build locally

## Dependencies

Per the Gemfile and CircleCI config:

- **Ruby**: 3.1 (cimg/ruby:3.1)
- **Bundler**: 2.4.17
- **Jekyll**: >= 3.10.0
- **GitHub Pages**: >= 232
- **html-proofer**: ~> 3.19.4
- **Docker**: Required for local development

## Security and Best Practices

- Never commit sensitive data or credentials
- Validate all external URLs before adding
- Use HTML escaping for user-provided content
- Keep dependencies updated per Gemfile
- Follow Jekyll security best practices

## Notes for Copilot

- **Minimal Changes**: Make surgical, precise changes to YAML files
- **Preserve Formatting**: Maintain existing indentation and structure
- **Validate Schema**: Always check against the data schema before modifying
- **Test First**: Understand existing build/test process before changes
- **Documentation**: Update README/CONTRIBUTING if making structural changes
- **Focus**: This project is specifically about testing conferences - don't include general tech conferences
