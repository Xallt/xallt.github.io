module RecipeUrlGenerator
  def self.recipe_name_to_url(recipe_name)
    return "" if recipe_name.nil?
    ru_to_en = {
      "а" => "a",
      "б" => "b",
      "в" => "v",
      "г" => "g",
      "д" => "d",
      "е" => "e",
      "ё" => "yo",
      "ж" => "zh",
      "з" => "z",
      "и" => "i",
      "й" => "j",
      "к" => "k",
      "л" => "l",
      "м" => "m",
      "н" => "n",
      "о" => "o",
      "п" => "p",
      "р" => "r",
      "с" => "s",
      "т" => "t",
      "у" => "u",
      "ф" => "f",
      "х" => "h",
      "ц" => "c",
      "ч" => "ch",
      "ш" => "sh",
      "щ" => "shh",
      "ъ" => "",
      "ы" => "y",
      "ь" => "",
      "э" => "e",
      "ю" => "yu",
      "я" => "ya",
    }
    url = recipe_name.to_s.strip.downcase
    url = url.chars.map { |c| ru_to_en[c] || c }.join
    url = url.gsub(/[^a-z0-9\-]/, '-').gsub(/-+/, '-').gsub(/^-|-$/, '')
    url
  end
end 