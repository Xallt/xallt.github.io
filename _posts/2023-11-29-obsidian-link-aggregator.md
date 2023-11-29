---
layout: post
title: Obsidian link aggregator
date: 2023-11-29
author: xallt
tags:
  - obsidian
  - javascript
categories:
  - Miscellaneous
  - Knowledge Management
---
I'm a big fan of the idea of preserving as many "useful" links as possible. A while ago I managed to educate myself about a lot of things in Computer Graphics and Machine Learning because of the great resources I stumbled upon online. 

Maybe if I keep all the links I find interesting / useful, I'll be able to share them with someone who might find them really helpful.

All of this motivated me to store everything I found interesting in my Obsidian Vault, and also make a script that would turn them into a biig table of all the links.

Each link I find interesting goes **into its own note**. I mark it's type in the frontmatter as either "link", "tool", "library", or whatever else I have. Each of those notes also has a "link" frontmatter property for the link itself.

> You can read more about my Obsidian Vault structure here: [Useful Obsidian templates/scripts]({% link _posts/2023-10-23-obsidian-useful-scripts.md %})

I use [Dataview](https://blacksmithgu.github.io/obsidian-dataview/) to collect all my relevant notes into a big table, using this Javascript snippet:

````javascript
```dataviewjs
const link_pages = dv.pages('"Notes" or "Definitions"').filter((page) => (page.type == "link" | page.type == "tool"));

async function load_page(page) {
	return await dv.io.load(page.file.path);
}

function get_description(file_content) {
	const file_content_lines = file_content.split('\n');
	const link_line_idx = file_content_lines.findIndex(line => line.startsWith("## Link: "));
	if (link_line_idx == -1) {
		return "";
	}
	const file_description_lines = file_content_lines.slice(link_line_idx + 1);
	return file_description_lines.join("\n");
}

dv.table(
	["Name", "Link", "Tags", "Description", "Type"],
	await Promise.all(link_pages.map(async (page) => [
		page.file.name,
		page.link,
		page.file.outlinks.join(", "),
		get_description(await load_page(page)),
		page.type
	]))
)
```
````

And then I use this [Table to CSV Exporter](https://github.com/metawops/obsidian-table-to-csv-export) plugin to turn the Dataview table into a CSV table that can be imported into Notion.

The latest version of my link aggregator is here: [https://rare-save-0fa.notion.site/6eedcf7b68b9454986b894456f165df2?v=8ef4d2426ec14874beb2bdd405190711](https://rare-save-0fa.notion.site/6eedcf7b68b9454986b894456f165df2?v=8ef4d2426ec14874beb2bdd405190711)

I should eventually work on either exporting this table automatically or integrating it into the website in a nicer way.