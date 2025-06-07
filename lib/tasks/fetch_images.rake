require 'open-uri'
require 'fileutils'

namespace :images do
  desc "Fetch and save 40 blurred images from picsum.photos"
  task fetch: :environment do
    destination_dir = Rails.root.join('db', 'seeds', 'images')
    FileUtils.mkdir_p(destination_dir)

    puts "Fetching 40 blurred images..."

    40.times do |i|
      filename = "image_#{i + 1}.jpg"
      filepath = destination_dir.join(filename)
      url = "https://random-image-pepebigotes.vercel.app/api/random-image"

      URI.open(url) do |image|
        File.open(filepath, "wb") do |file|
          file.write(image.read)
        end
      end

      puts "Saved #{filename}"
      sleep(0.3) # short delay to avoid caching/reuse of the same image
    end

    puts "Done! Images saved to #{destination_dir}"
  end
end
