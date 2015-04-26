---
layout: page
title: Past
permalink: /past/
---

This basic list is generated from the past data file:

<ul>
{% for past in site.data.past %}
  <li>
      <a href="{{past.url}}">{{ past.name }}</a>, {{ past.reg_phrase }},
      {{ past.dates }}, {{ past.location }}, <a href="https://www.twitter.com/{{past.twitter}}">@{{ past.twitter }}</a>, <a href="{{past.video_link}}">Event Videos</a>
  </li>

{% endfor %}
</ul>
