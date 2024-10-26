Initialized from **Chirpy Jekyll Theme**. For details on this amazing Jekyll theme, head [here](https://github.com/cotes2020/jekyll-theme-chirpy)

# Setup

## Update/install packages
```bash
bundle install
```

## Development Environment
```bash
bundle exec jekyll serve --livereload
```

## Building Javascript
When first running the website, or when changing the javascript, the minimized ".min.js" files have to be rebuilt
```bash
npm run build
```

## Notes

- Automatic recipe collection for the `/recipes` tab requires a Notion API key. Either specify one with `export NOTION_API_KEY=...`, or create a `.env` file in the root directory with the environment variable set.
- To set up the Python environment for recipe collection:
  ```bash
  python3 -m venv .venv
  source .venv/bin/activate  # On Windows, use `.venv\Scripts\activate`
  pip install requests
  ```