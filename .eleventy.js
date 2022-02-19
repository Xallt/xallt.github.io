const { DateTime } = require('luxon');
const readingTime = require('eleventy-plugin-reading-time');
const scrape = require('html-metadata');
const { EleventyRenderPlugin } = require("@11ty/eleventy");
const pluginRss = require('@11ty/eleventy-plugin-rss');
const syntaxHighlight = require('@11ty/eleventy-plugin-syntaxhighlight');
const htmlmin = require('html-minifier')
const fs = require('fs');
const path = require('path');

const isDev = process.env.ELEVENTY_ENV === 'development';
const isProd = process.env.ELEVENTY_ENV === 'production';
const publishPath = 'docs';

const manifestPath = path.resolve(
  __dirname,
  publishPath,
  'assets',
  'manifest.json'
);

const manifest = isDev
  ? {
      'main.js': '/assets/main.js',
      'main.css': '/assets/main.css',
    }
  : JSON.parse(fs.readFileSync(manifestPath, { encoding: 'utf8' }));

module.exports = function (eleventyConfig) {
  eleventyConfig.addPlugin(readingTime);
  eleventyConfig.addPlugin(pluginRss);
  eleventyConfig.addPlugin(syntaxHighlight);
  eleventyConfig.addPlugin(EleventyRenderPlugin);


  // setup mermaid markdown highlighter
  const highlighter = eleventyConfig.markdownHighlighter;
  eleventyConfig.addMarkdownHighlighter((str, language) => {
    if (language === 'mermaid') {
      return `<pre class="mermaid">${str}</pre>`;
    }
    return highlighter(str, language);
  });

  eleventyConfig.setDataDeepMerge(true);
  eleventyConfig.addPassthroughCopy({ 'src/images': 'images' });
  eleventyConfig.addPassthroughCopy({ 'src/gifs': 'gifs' });
  eleventyConfig.setBrowserSyncConfig({ files: [manifestPath] });

  eleventyConfig.addShortcode('bundledcss', function () {
    return manifest['main.css']
      ? `<link href="${manifest['main.css']}" rel="stylesheet" />`
      : '';
  });

  eleventyConfig.addShortcode('bundledjs', function () {
    return manifest['main.js']
      ? `<script src="${manifest['main.js']}"></script>`
      : '';
  });

  eleventyConfig.addFilter('excerpt', (post) => {
    const content = post.replace(/(<([^>]+)>)/gi, '');
    return content.substr(0, content.lastIndexOf(' ', 200)) + '...';
  });

  eleventyConfig.addFilter('readableDate', (dateObj) => {
    return DateTime.fromJSDate(dateObj, { zone: 'utc' }).toFormat(
      'dd LLL yyyy'
    );
  });

  eleventyConfig.addFilter('htmlDateString', (dateObj) => {
    return DateTime.fromJSDate(dateObj, { zone: 'utc' }).toFormat('yyyy-LL-dd');
  });

  eleventyConfig.addFilter('dateToIso', (dateString) => {
    return new Date(dateString).toISOString()
  });

  eleventyConfig.addFilter('head', (array, n) => {
    if (n < 0) {
      return array.slice(n);
    }

    return array.slice(0, n);
  });

  eleventyConfig.addCollection('tagList', function (collection) {
    let tagSet = new Set();
    collection.getAll().forEach(function (item) {
      if ('tags' in item.data) {
        let tags = item.data.tags;

        tags = tags.filter(function (item) {
          switch (item) {
            case 'all':
            case 'nav':
            case 'post':
            case 'posts':
              return false;
          }

          return true;
        });

        for (const tag of tags) {
          tagSet.add(tag);
        }
      }
    });

    return [...tagSet];
  });

  eleventyConfig.addFilter('pageTags', (tags) => {
    const generalTags = ['all', 'nav', 'post', 'posts'];

    return tags
      .toString()
      .split(',')
      .filter((tag) => {
        return !generalTags.includes(tag);
      });
  });

  eleventyConfig.addTransform('htmlmin', function(content, outputPath) {
    if ( outputPath && outputPath.endsWith(".html") && isProd) {
      return htmlmin.minify(content, {
        removeComments: true,
        collapseWhitespace: true,
        useShortDoctype: true,
      });
    }

    return content;
  });

  eleventyConfig.addShortcode("git_link", function (link) {
    return `[Github Link](${link})`;
  });

  eleventyConfig.addShortcode("link", async function (link) {
    // Credit to https://www.jefago.com/technology/rich-link-previews-in-eleventy-and-nunjucks/
    const escape = (unsafe) => {
      return (unsafe === null) ? null : 
        unsafe.replace(/&/g, "&amp;")
          .replace(/</g, "&lt;")
          .replace(/>/g, "&gt;")
          .replace(/"/g, "&quot;")
          .replace(/'/g, "&#039;");
    }
    function extract_meaningful_metadata(metadata) {
      let domain = link.replace(/^http[s]?:\/\/([^\/]+).*$/i, '$1');
      let title = escape((metadata.openGraph ? metadata.openGraph.title : null) || metadata.general.title || "");
      let author = escape(((metadata.jsonLd && metadata.jsonLd.author) ? metadata.jsonLd.author.name : null) || "");
      let image = escape((metadata.openGraph && metadata.openGraph.image) ? (Array.isArray(metadata.openGraph.image) ? metadata.openGraph.image[0].url : metadata.openGraph.image.url) : null);
      let description = escape(((metadata.openGraph ? metadata.openGraph.description : "") || metadata.general.description || "").trim());
      if (description.length > 140) {
        description = description.replace(/^(.{0,140})\s.*$/s, '$1') + '…';
      }
      return {
        'link': link,
        'domain': domain,
        'title': title,
        'author': author,
        'image': image,
        'description': description
      }
    }
    
    return scrape(link).then(metadata => {
      meaningful_metadata = extract_meaningful_metadata(metadata);
      console.log(meaningful_metadata);
      return eleventyConfig.javascriptFunctions.renderFile('./src/includes/link-preview.njk', meaningful_metadata, "njk");
    });
      
  });

  eleventyConfig.addShortcode("img", function (content_link) {
    // From https://stackoverflow.com/questions/7840306/parse-url-with-javascript-or-jquery
    let link_parts = content_link.replace(/\/\s*$/, '').split('/');
    description = link_parts[link_parts.length - 1];

    // Access other arguments of the function as additional attributes for img tag
    let other_arguments = Array.from(arguments).slice(1);

    let content_link_normalized = eleventyConfig.javascriptFunctions.url(content_link);
    return `<img src="${content_link_normalized}" alt="${description}" ${other_arguments.join(' ')}>`
  });

  return {
    dir: {
      input: 'src',
      output: publishPath,
      includes: 'includes',
      data: 'data',
      layouts: 'layouts',
      passthroughFileCopy: true,
      templateFormats: ['html', 'njk', 'md'],
      htmlTemplateEngine: 'njk',
      markdownTemplateEngine: 'njk',
    },
  };
};
