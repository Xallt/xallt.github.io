#!/usr/bin/env ruby

require_relative './recipe_collector'
require_relative './url_generator'
require_relative './recipe'
require 'dotenv'

# Load environment variables from .env file
Dotenv.load

def print_recipe(recipe)
  puts "\n#{'=' * 50}"
  puts "Recipe: #{recipe.name}"
  puts "URL: #{recipe.url}"
  puts "Generated URL path: /recipes/#{RecipeUrlGenerator.recipe_name_to_url(recipe.name)}"
  puts "ID: #{recipe.id}"
  puts "-" * 50
  puts "Content:"
  puts recipe.text
  puts "=" * 50
end

begin
  api_key = ENV['NOTION_API_KEY']
  unless api_key
    puts "Error: NOTION_API_KEY environment variable is not set"
    puts "Please set it in your .env file or with: export NOTION_API_KEY=your_api_key"
    exit 1
  end

  puts "Fetching recipes from Notion..."
  collector = RecipeCollector.new(api_key: api_key)
  recipes = collector.get_recipe_data(limit: 1)

  if recipes.empty?
    puts "No recipes found in the database"
    exit 1
  end

  recipes.each do |recipe|
    print_recipe(recipe)
  end

rescue RecipeCollector::Error => e
  puts "Error: #{e.message}"
  exit 1
rescue StandardError => e
  puts "Unexpected error: #{e.message}"
  puts e.backtrace
  exit 1
end 