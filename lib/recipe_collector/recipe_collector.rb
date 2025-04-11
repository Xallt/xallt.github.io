require 'json'
require 'httparty'
require_relative './recipe'

class RecipeCollector
  class Error < StandardError; end
  class NotionAPIError < Error; end
  class ConfigurationError < Error; end
  class ValidationError < Error; end

  DEFAULT_DATABASE_ID = "013eb25bb1444da6a8a842fba94b3f0e"
  VALID_BLOCK_TYPES = ["paragraph", "bulleted_list_item", "numbered_list_item"].freeze

  def initialize(api_key: nil, database_id: nil)
    @api_key = api_key
    @database_id = database_id || DEFAULT_DATABASE_ID
    @headers = {
      "Authorization" => "Bearer #{@api_key}",
      "Notion-Version" => "2022-06-28",
      "Content-Type" => "application/json"
    }
  end

  def get_recipe_data(notion_api_key = nil, limit: nil)
    @api_key = notion_api_key if notion_api_key
    raise ConfigurationError, "Notion API key is required" if @api_key.nil? || @api_key.empty?
    raise ValidationError, "Limit must be a positive integer" if limit && (!limit.is_a?(Integer) || limit <= 0)
    
    update_headers
    get_all_recipes_data(limit: limit)
  rescue HTTParty::Error => e
    raise NotionAPIError, "HTTP request failed: #{e.message}"
  end

  private

  def update_headers
    @headers["Authorization"] = "Bearer #{@api_key}"
  end

  def get_all_recipes_data(limit: nil)
    db_data = get_db_data(limit: limit)
    db_data["results"].map do |recipe_data|
      begin
        basic_data = extract_recipe_data(recipe_data)
        recipe_text = get_recipe_text(basic_data.id)
        Recipe.new(
          id: basic_data.id,
          name: basic_data.name,
          url: basic_data.url,
          text: recipe_text
        )
      rescue => e
        warn "WARNING: Failed to process recipe: #{e.message}"
        nil
      end
    end.compact
  end

  def get_db_data(limit: nil)
    body = {}
    body[:page_size] = limit if limit

    response = HTTParty.post(
      "https://api.notion.com/v1/databases/#{@database_id}/query",
      headers: @headers,
      body: body.to_json
    )

    handle_response(response) do |data|
      raise NotionAPIError, "No results found in response" unless data["results"]
      data
    end
  end

  def get_recipe_text(recipe_id)
    raise ValidationError, "Recipe ID is required" if recipe_id.nil? || recipe_id.empty?

    recipe_page_data = get_recipe_page_data(recipe_id)
    content_lines = []
    counter = 0

    recipe_page_data["results"].each do |block|
      block_type = block["type"]
      unless VALID_BLOCK_TYPES.include?(block_type)
        warn "WARNING: Can't handle #{block_type} yet"
        next
      end

      block_rich_text = block[block_type]["rich_text"] rescue []
      if block_rich_text.empty?
        content_lines << ""
        next
      end

      if block_type == "numbered_list_item"
        counter += 1
      else
        counter = 0
      end

      line = case block_type
      when "bulleted_list_item"
        "- #{block_rich_text[0]["plain_text"]}"
      when "numbered_list_item"
        "#{counter}. #{block_rich_text[0]["plain_text"]}"
      else
        block_rich_text[0]["plain_text"]
      end

      content_lines << line
    end

    content_lines.join("\n")
  rescue => e
    warn "WARNING: Failed to get recipe text: #{e.message}"
    ""
  end

  def extract_recipe_data(item)
    raise ValidationError, "Recipe item is required" if item.nil?
    
    name = extract_text_safely(item, ["properties", "Name", "title", 0, "plain_text"])
    warn "DEBUG: Extracted name: #{name.inspect}"
    
    Recipe.new(
      id: item["id"],
      name: name,
      url: extract_text_safely(item, ["properties", "URL", "url"])
    )
  rescue => e
    raise ValidationError, "Failed to extract recipe data: #{e.message}"
  end

  def extract_text_safely(hash, keys)
    keys.reduce(hash) { |h, key| h&.[](key) }
  end

  def get_recipe_page_data(recipe_id)
    response = HTTParty.get(
      "https://api.notion.com/v1/blocks/#{recipe_id}/children",
      headers: @headers
    )

    handle_response(response)
  end

  def handle_response(response)
    unless response.success?
      raise NotionAPIError, "API request failed: #{response.code} - #{response.body}"
    end

    data = JSON.parse(response.body)
    block_given? ? yield(data) : data
  rescue JSON::ParserError => e
    raise NotionAPIError, "Failed to parse API response: #{e.message}"
  end
end 