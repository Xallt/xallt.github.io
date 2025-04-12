---
layout: page
title: Interesting Links
icon: fas fa-link
order: 5
---

Below is a curated collection of interesting links, auto-extracted from my [Obsidian](https://obsidian.md/) vault:

| Name | Description | Tags |
|------|-------------|------|
{% for link in site.data.links %}| [{{ link.name }}]({{ link.url }}) | {{ link.short_description }} | {% for tag in link.tags %}`{{ tag }}`{% unless forloop.last %} {% endunless %}{% endfor %} |
{% endfor %} 