
require 'open-uri'
require 'json'
require 'fileutils'

dir = Rails.root.join('db', 'seeds', 'images')
FileUtils.mkdir_p(dir)

sfw_tags = %w[hug blush happy slap kill cry dance]

puts "⬇️ Downloading 100 waifu images with random tags..."

20.times do |i|
  begin
    tag = sfw_tags.sample
    # api_url = "https://api.waifu.pics/sfw/#{tag}"
    api_url = "https://picsum.photos/200"

    # api_response = URI.open(api_url).read
    # image_url = JSON.parse(api_response)['url']
    image_url ="https://picsum.photos/200"

    extension = ".png"
    filename = "img_#{i + 1}#{extension}"
    filepath = dir.join(filename)

    URI.open(image_url) do |image|
      File.open(filepath, 'wb') { |f| f.write(image.read) }
    end

    puts "✅ Saved #{filename})"
  rescue => e
    puts "⚠️ Failed on image #{i + 1} (#{tag}): #{e.message}"
  end
end
