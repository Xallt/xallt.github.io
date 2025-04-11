class Recipe
  attr_reader :id, :name, :url, :text

  def initialize(id:, name:, url: nil, text: nil)
    @id = id
    @name = name.to_s.strip
    @url = url
    @text = text
  end

  def to_h
    {
      'id' => id,
      'name' => name,
      'url' => url,
      'text' => text
    }
  end

  def self.from_h(hash)
    new(
      id: hash['id'] || hash[:id],
      name: hash['name'] || hash[:name],
      url: hash['url'] || hash[:url],
      text: hash['text'] || hash[:text]
    )
  end
end 