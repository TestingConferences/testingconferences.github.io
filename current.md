---
layout: page
title: Current
permalink: /current/
---

This basic list is generated from the current data file:

<ul>
{% for current in site.data.current %}
  <li>
      <a href="{{current.url}}">{{ current.name }}</a>, {{ current.reg_phrase }},
      {{ current.dates }}, {{ current.location }}, {{ current.twitter }}
  </li>

{% endfor %}
</ul>


1. See if I can make this the index.html page?
2. Change the existing index.html page to the news.html page?
3. Markdown works on pages (.md extension)
