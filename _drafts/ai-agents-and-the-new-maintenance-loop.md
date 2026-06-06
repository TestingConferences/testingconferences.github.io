---
layout: post
title: "AI Agents and the New Maintenance Loop"
categories: news
author: Chris Kenst
permalink: /ai-agents-and-the-new-maintenance-loop/
twitter:
  username: testconferences
  card: summary
social:
  links:
    - https://twitter.com/testconferences
    - https://github.com/testingconferences
---

## From Hand-Checked Lists to Agent-Assisted Maintenance

When I first started this project, I would occasionally check statuses and add conferences. I would also look at the list and move completed conferences to the past list when I noticed them.

The monthly newsletter became the true forcing function. Before writing it, I would spend two or more hours diligently checking each conference to make sure it had not changed dates, been canceled, opened registration, closed its CFP, or otherwise updated important details.

Then I would artisanally handcraft the newsletter.

Today things are a bit different.

Today I can bring up Codex and ask it to check for outdated conferences and statuses. Codex can, in turn, launch sub-agents that split up the list and iterate through each conference. Each agent can load the website, inspect the details, compare them against the data file, and report what looks stale or wrong.

When I tried doing this in the past it was difficult. Every conference website is built differently. Some sites hide details behind JavaScript. Some move ticket information to a separate vendor. Some have registration links, CFP links, date banners, pricing tables, and old announcements all competing for attention on the same page. Some websites just could not be scraped reliably.

The difference now is that the agents are good enough to reason through that mess with relatively little guidance. They can look at the page more like a person would: find the event date, notice that an early-bird deadline has passed, see that the CFP is closed, or flag a page where the official status is inconsistent.

It is not magic, and it is not hands-off. I still review the findings. I still decide what wording belongs on the site. I still need to catch edge cases, especially when an organizer has contradictory information in different places.

But the maintenance loop has changed.

Instead of spending all my energy manually checking the same list from top to bottom, I can spend more of it reviewing, deciding, and improving the site. The agents do the first pass. I do the judgment pass.

That is a big shift for a small community project like this one. TestingConferences.org has always depended on regular, careful updates. For years, that meant a lot of quiet manual work. Now the work is still there, but it is shaped differently.

It has taken many hours of experimenting to get here. The early attempts were brittle. The agents missed obvious things, followed the wrong links, or got confused by pages with old and new events mixed together. But the tools have improved, and so has my understanding of how to ask for the right kind of help.

The result is not a replacement for maintaining the site. It is a better maintenance partner.

And for a project that has been running for more than a decade, that feels like a meaningful new chapter.
