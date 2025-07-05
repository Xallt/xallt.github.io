#!/bin/bash

# Development server script with recipe generation disabled
# This makes live reload much faster during development

echo "Starting Jekyll development server..."
echo "Recipe generation is DISABLED for faster live reload"
echo "To enable recipes, run: bundle exec jekyll serve --livereload"
echo "To clear recipe cache, run: ./tools/clear_recipe_cache.sh"
echo ""

# Enable development mode to skip recipe generation
export JEKYLL_DEV_MODE=true

# Start Jekyll with live reload
bundle exec jekyll serve --livereload --incremental 