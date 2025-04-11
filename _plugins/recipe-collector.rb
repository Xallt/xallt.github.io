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
        
        # Prepend each name with a dash
        recipe_names = recipe_data.map do |recipe| 
          name = recipe.name
          url = "/recipes/#{RecipeCollectorWrapper.recipe_name_to_url(name)}"
          "- <a href=\"#{url}\">#{name}</a>\n\n"
        end

        # Join the array into a string
        recipe_names.join("\n")
      rescue => e
        warn "WARNING: Failed to render recipe names: #{e.message}"
        "Error loading recipes"
      end
    end
  end

  class RecipeCollectorGenerator < Jekyll::Generator
    def generate(site)
      begin
        notion_api_key = ENV['NOTION_API_KEY']
        raise RecipeCollectorError, "NOTION_API_KEY environment variable is not set" if notion_api_key.nil? || notion_api_key.empty?

        recipe_data = RecipeCollectorWrapper.get_recipe_data(notion_api_key, RecipeCollectorModule.get_recipe_limit)
        recipe_data.each do |recipe|
          begin
            site.pages << RecipePage.new(site, site.source, recipe.name, recipe.text, recipe.url)
          rescue => e
            warn "WARNING: Failed to generate page for recipe '#{recipe.name}': #{e.message}"
          end
        end
      rescue => e
        warn "WARNING: Failed to generate recipe pages: #{e.message}"
      end
    end
  end

  class RecipePage < Jekyll::Page 
    def initialize(site, base, recipe_name, recipe_text, recipe_url)
      @site = site
      @base = base
      @dir = "recipes/#{RecipeCollectorWrapper.recipe_name_to_url(recipe_name)}"

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
