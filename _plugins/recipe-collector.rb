require "recipe_collector"

module Jekyll
  class RecipeCollectorNamesTag < Liquid::Tag

    def initialize(tag_name, text, tokens)
      super
      @text = text
    end

    def render(context)
      notion_api_key = ENV['NOTION_API_KEY']
      # Get the list of recipe names
      recipes = RecipeCollector.new.get_recipes(notion_api_key)
      # Split the list into an array
      recipe_names = recipes.split("\n")
      # Prepend each name with a dash
      recipe_names.map! { |name| "- #{name}" }
      # Join the array into a string
      recipe_names.join("\n")
    end
  end
end

Liquid::Template.register_tag('recipes_collector_names', Jekyll::RecipeCollectorNamesTag)
