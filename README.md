# Dmitry Shabat's Personal Website

[![Jekyll site CI](https://github.com/Xallt/xallt.github.io/actions/workflows/jekyll.yml/badge.svg)](https://github.com/Xallt/xallt.github.io/actions/workflows/jekyll.yml)

This repository contains the source code for my personal website, hosted at [xallt.github.io](https://xallt.github.io). The site is built with Jekyll using the Chirpy theme and includes custom features like a recipe collection system.

## 📋 Site Structure

```
.
├── _data/               # Site data files
├── _includes/           # Reusable HTML components
├── _javascript/         # JavaScript source files
├── _layouts/            # Page layout templates
├── _plugins/            # Custom Jekyll plugins (including recipe collector)
├── _posts/              # Blog posts in Markdown format
├── _sass/               # SCSS style files
├── _site/               # Generated site (not committed)
├── _tabs/               # Navigation tabs content
├── assets/              # Static assets (images, CSS, JS)
├── tools/               # Utility scripts
└── docs/                # Documentation
```

## ✨ Features

### 🌟 Blog with Chirpy Theme
- Responsive design optimized for both desktop and mobile
- Dark/light mode toggle
- Category and tag support
- SEO optimized
- Code syntax highlighting

### 🍳 Recipe Collection System
- Automatically pulls recipes from a Notion database
- Generates individual pages for each recipe
- Transliterates Russian recipe names to English URLs
- Accessible via the "Family menu" tab

### 📝 Markdown-Based Content
- All content is written in Markdown for easy editing
- Support for math equations using MathJax
- Image optimization built-in

### 🛠️ Utility Scripts
- Post creation script to easily generate new blog posts with proper front matter
- Recipe collection automation

## 🚀 Development Setup

### Prerequisites
- Ruby (with Bundler)
- Node.js and npm
- Python 3 (for recipe collection and utility scripts)

### Initial Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/Xallt/xallt.github.io.git
   cd xallt.github.io
   ```

2. Install Ruby dependencies:
   ```bash
   bundle install
   ```

3. Install Node.js dependencies:
   ```bash
   npm install
   ```

4. Set up Python environment for recipe collection and utility scripts:
   ```bash
   python3 -m venv .venv
   source .venv/bin/activate  # On Windows, use `.venv\Scripts\activate`
   pip install requests
   pip install -r tools/requirements.txt
   ```

5. Configure Notion API for recipe collection:
   - Create a `.env` file in the root directory with:
     ```
     NOTION_API_KEY=your_notion_api_key
     ```
   - Or set the environment variable directly:
     ```bash
     export NOTION_API_KEY=your_notion_api_key
     ```

### Development Workflow

1. Start the development server with live reload:
   ```bash
   bundle exec jekyll serve --livereload
   ```

2. Build JavaScript files (required when changing JS code):
   ```bash
   npm run build
   ```

3. Access the local site at [http://localhost:4000](http://localhost:4000)

## 📝 Content Management

### Adding a New Blog Post

#### Using the Post Creation Script (Recommended)
1. Run the post creation script:
   ```bash
   # Activate Python environment if not already active
   source .venv/bin/activate  # On Windows, use `.venv\Scripts\activate`
   # For fish shell, use:
   # source .venv/bin/activate.fish
   
   # Run the script
   python tools/create_post.py
   ```

2. Follow the streamlined interactive prompts to:
   - Enter the post title
   - Select a main category and a sub-category (Chirpy theme requires exactly two categories)
   - Select tags from existing ones or create new ones

3. The script will create a properly formatted Markdown file with these default settings:
   - Math support: Enabled
   - Table of contents: Enabled
   - Mermaid diagrams: Disabled
   - Post pinning: Disabled

4. Edit the created file to add your content.

5. If needed, manually add image paths or descriptions to the front matter after writing some content.

#### Manual Creation
1. Create a new Markdown file in the `_posts` directory with the format:
   ```
   YYYY-MM-DD-title-with-hyphens.md
   ```

2. Include the front matter at the top:
   ```yaml
   ---
   title: Your Post Title
   date: YYYY-MM-DD HH:MM:SS +/-TTTT
   categories: [Main Category, Sub Category]  # Exactly two categories required
   tags: [tag1, tag2]
   math: true  # Enable math support
   ---
   ```

3. Write your content in Markdown below the front matter.

### Managing Recipes
- Recipes are automatically pulled from your Notion database
- The recipe collector plugin (`_plugins/recipe-collector.rb`) handles the conversion
- Make sure your Notion API key is set correctly

## 🔧 Maintenance

### Updating Dependencies
- Update Ruby gems: `bundle update`
- Update npm packages: `npm update`

### Troubleshooting Common Issues
- If the site doesn't build, check the Jekyll error messages
- For JavaScript issues, ensure you've run `npm run build` after making changes
- For recipe collection issues, verify your Notion API key is correct
- If the post creation script fails, ensure you have the required Python packages installed

## 📚 Resources

- [Jekyll Documentation](https://jekyllrb.com/docs/)
- [Chirpy Theme Documentation](https://github.com/cotes2020/jekyll-theme-chirpy/wiki)
- [GitHub Pages Documentation](https://docs.github.com/en/pages)

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

*This site was initialized from the [Chirpy Jekyll Theme](https://github.com/cotes2020/jekyll-theme-chirpy).*