require_relative "../lib/recipe_collector/recipe_collector"
require_relative "../lib/recipe_collector/url_generator"
require_relative "../lib/recipe_collector/recipe"
require "dotenv"

# Load environment variables (NOTION_API_KEY)
Dotenv.load

module RecipeCollectorModule
  class RecipeCollectorError < StandardError; end

  def self.get_recipe_limit
    test_mode = ENV['TEST_BUILD_MODE']
    return 3 if test_mode && (test_mode == 'true' || test_mode == '1')
    nil
  end

  class BuildRecipeCache
    @@instance = nil

    def self.instance
      @@instance ||= new
    end

    def initialize
      @cache = {}
    end

    def get_recipe_data(notion_api_key, limit = nil)
      cache_key = "#{notion_api_key}_#{limit}"
      
      return @cache[cache_key] if @cache.key?(cache_key)

      begin
        recipes = RecipeCollector.new.get_recipe_data(notion_api_key, limit: limit)
        @cache[cache_key] = recipes
      rescue RecipeCollector::Error => e
        warn "WARNING: Failed to fetch recipe data: #{e.message}"
        @cache[cache_key] = []
      end
      
      @cache[cache_key]
    end
  end

  class RecipeCollectorWrapper
    def self.get_recipe_data(notion_api_key, limit = nil)
      BuildRecipeCache.instance.get_recipe_data(notion_api_key, limit)
    end

    def self.recipe_name_to_url(recipe_name)
      RecipeUrlGenerator.recipe_name_to_url(recipe_name)
    end
    
    def self.get_unique_url_path(recipe_name, url_counter)
      base_url = RecipeUrlGenerator.recipe_name_to_url(recipe_name)
      return base_url if url_counter[base_url] == 1
      
      # If this URL appears multiple times, add an index
      index = url_counter[base_url + "_indexes"][recipe_name]
      "#{base_url}-#{index}"
    end
  end

  class RecipeCollectorNamesTag < Liquid::Tag
    def initialize(tag_name, text, tokens)
      super
      @text = text
    end

    def render(context)
      begin
        notion_api_key = ENV['NOTION_API_KEY']

        raise RecipeCollectorError, "NOTION_API_KEY environment variable is not set" if notion_api_key.nil? || notion_api_key.empty?
        # Get recipe data
        recipe_data = RecipeCollectorWrapper.get_recipe_data(notion_api_key, RecipeCollectorModule.get_recipe_limit)
        
        # Generate URL counter dictionary
        url_counter = generate_url_counter(recipe_data)
        
        # Prepend each name with a dash
        recipe_names = recipe_data.map do |recipe| 
          name = recipe.name
          url = "/recipes/#{RecipeCollectorWrapper.get_unique_url_path(name, url_counter)}"
          "- <a href=\"#{url}\">#{name}</a>\n\n"
        end

        # Join the array into a string
        recipe_names.join("\n")
      rescue => e
        warn "WARNING: Failed to render recipe names: #{e.message}"
        "Error loading recipes"
      end
    end
    
    private
    
    def generate_url_counter(recipe_data)
      counter = {}
      
      # First pass: count occurrences of each URL
      recipe_data.each do |recipe|
        url = RecipeCollectorWrapper.recipe_name_to_url(recipe.name)
        counter[url] ||= 0
        counter[url] += 1
        # Initialize index tracking for each URL
        counter[url + "_indexes"] ||= {}
      end
      
      # Second pass: assign indexes to recipes with the same URL
      recipe_data.each do |recipe|
        url = RecipeCollectorWrapper.recipe_name_to_url(recipe.name)
        if counter[url] > 1
          counter[url + "_indexes"] ||= {}
          counter[url + "_indexes"][recipe.name] ||= counter[url + "_indexes"].size + 1
        end
      end
      
      counter
    end
  end

  class RecipeCollectorGenerator < Jekyll::Generator
    def generate(site)
      begin
        # Check if we should skip recipe generation during development
        if ENV['JEKYLL_DEV_MODE'] == 'true'
          puts "DEBUG: Skipping recipe generation (JEKYLL_DEV_MODE=true)"
          return
        end
        
        notion_api_key = ENV['NOTION_API_KEY']
        raise RecipeCollectorError, "NOTION_API_KEY environment variable is not set" if notion_api_key.nil? || notion_api_key.empty?

        puts "DEBUG: Starting recipe generation..."
        recipe_data = RecipeCollectorWrapper.get_recipe_data(notion_api_key, RecipeCollectorModule.get_recipe_limit)
        
        # Generate URL counter dictionary
        url_counter = generate_url_counter(recipe_data)
        
        recipe_data.each do |recipe|
          begin
            unique_url_path = RecipeCollectorWrapper.get_unique_url_path(recipe.name, url_counter)
            site.pages << RecipePage.new(site, site.source, recipe.name, recipe.text, recipe.url, unique_url_path)
          rescue => e
            warn "WARNING: Failed to generate page for recipe '#{recipe.name}': #{e.message}"
          end
        end
      rescue => e
        warn "WARNING: Failed to generate recipe pages: #{e.message}"
      end
    end
    
    private
    
    def generate_url_counter(recipe_data)
      counter = {}
      
      # First pass: count occurrences of each URL
      recipe_data.each do |recipe|
        url = RecipeCollectorWrapper.recipe_name_to_url(recipe.name)
        counter[url] ||= 0
        counter[url] += 1
        # Initialize index tracking for each URL
        counter[url + "_indexes"] ||= {}
      end
      
      # Second pass: assign indexes to recipes with the same URL
      recipe_data.each do |recipe|
        url = RecipeCollectorWrapper.recipe_name_to_url(recipe.name)
        if counter[url] > 1
          counter[url + "_indexes"] ||= {}
          counter[url + "_indexes"][recipe.name] ||= counter[url + "_indexes"].size + 1
        end
      end
      
      counter
    end
  end

  class RecipePage < Jekyll::Page 
    def initialize(site, base, recipe_name, recipe_text, recipe_url, url_path = nil)
      @site = site
      @base = base
      
      # Use the provided unique URL path if available, otherwise generate from name
      @dir = "recipes/#{url_path || RecipeCollectorWrapper.recipe_name_to_url(recipe_name)}"

      @basename = 'index'
      @ext = '.html'
      @name = 'index.html'

      recipe_text_full = ""
      # if url is not nil, add a link to the recipe
      if recipe_url 
        recipe_text_full += "<a href=\"#{recipe_url}\">#{recipe_name}</a>\n\n"
      end
      recipe_text_full += recipe_text.to_s
      
      recipe_text_full.gsub!("\n", "<br>\n")

      @content = recipe_text_full

      @data = {
        'layout' => 'page',
        'title' => recipe_name.to_s
      }
    end
  end
end

Liquid::Template.register_tag('recipes_collector_names', RecipeCollectorModule::RecipeCollectorNamesTag)
