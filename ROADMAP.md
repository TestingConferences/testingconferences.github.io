# Roadmap: testingconferences.org

## Project Vision
Continue to use TCorg to experiment and learn. I want to track quality metrics automatically. Yes these are indirect quality metrics, but I'd like to see what I can track on the build side and how it works. Then improve upon them later.

---

## Phase 1: Versioning & Traceability (High Priority)
*Goal: Establish a "Source of Truth" for site deployments.*

- [x] **Implement `VERSION` file**: Create a plaintext file in the root directory to track SemVer (e.g., `1.0.0`).
- [ ] **Footer Integration**: Update the website footer to dynamically display the current string from the `VERSION` file.
- [ ] **Automated Increments**: Create a workflow to increment the `VERSION` file on every deployment.
- [ ] **Deployment Tagging**: Ensure every production deploy is tagged in Git to match the internal version.

## Phase 2: Quality Ledger & Metrics
*Goal: Associate every site version with a specific quality snapshot.*

- [ ] **Lighthouse Tracking**: Automate Lighthouse audits during CI and record Performance, Accessibility, and SEO scores per version.
- [ ] **Link Integrity**: Implement a broken link checker (e.g., `linkinator`) to log broken link counts against the current version.
- [ ] **Build Analytics**: Track and log build times to monitor the impact of site growth on CI/CD performance.
- [ ] **Bug Attribution**: Update Issue Templates to include a "Site Version" field to track bug counts relative to specific releases.

## Phase 3: Developer Experience (DX) & AI Workflows
*Goal: Streamline contributions using automation and AI context.*

- [ ] **Automatic Linting**: Set up Prettier and ESLint with pre-commit hooks (Husky) to ensure code consistency.
- [ ] **AI Contextualization**: Create a `.github/copilot-instructions.md` to help GitHub Copilot understand the conference data schema and project goals.
- [ ] **Prompt Imports**: Build a library of standardized prompts to assist contributors in formatting and validating new conference submissions.

## Phase 4: Public Quality Dashboard
*Goal: Surface project health and transparency to the community.*

- [ ] **Metrics Dashboard**: Build a public-facing page (e.g., `/stats` or `/quality`) to visualize project health.
- [ ] **Trend Visualization**: Display historical graphs of Lighthouse scores, bug counts, and conference growth over different versions.
- [ ] **Live Status Badges**: Integrate dynamic README badges for current version, build status, and site health.

## Misc:
*Goal: Other important features

- [ ] **Calendar Download**: Make it possible to just download the current TC.org data as a ICO and import it into your calendar
- [ ] **Reference License in Footer**: Should we reference our MIT-LICENSE file in super footer?

---

## Version History & Quality Log
*This table tracks the evolution of the site's quality over time.*

| Version | Release Date | Lighthouse (Perf) | Broken Links | Build Time | Bugs Found |
| :--- | :--- | :--- | :--- | :--- | :--- |
| v1.0.0 | 2025-XX-XX | TBD | TBD | TBD | TBD |

---
*Last Updated: December 2025*