# lib/tasks/waifu_downloader.rake
namespace :waifu do
  desc "Download 100 random GIF waifu images"
  task download: :environment do
    load "db/scripts/fetch_images.rb"
  end
end
