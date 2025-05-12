require 'open-uri'
require 'net/http'
require 'json'
require 'faker'
require 'concurrent'

FAST = ENV['FAST'] == 'true'

def log(message)
  puts message
  sleep(rand(1..2)) unless FAST
end

def fetch_waifu_image_async
  Concurrent::Promises.future do
    uri = URI('https://api.waifu.pics/sfw/hug')
    response = Net::HTTP.get(uri)
    JSON.parse(response)['url']
  rescue => e
    puts "⚠️ Image fetch failed: #{e.message}"
    nil
  end
end

puts "🌱 Starting database seeding...#{FAST ? ' (FAST mode enabled)' : ''}"

# Users
users = 1.times.map do
  user = User.create!(
    email: Faker::Internet.unique.email,
    password: 'password123',
    role: %w[user admin].sample
  )
  log("✅ Created user: #{user.email} (#{user.role})")
  user
end

# Records
records = 15.times.map do |i|
  user = users.sample
  record = Record.create!(
    name: Faker::Name.name,
    contact_number: Faker::PhoneNumber.cell_phone,
    address: Faker::Address.full_address,
    pincode: Faker::Address.zip_code,
    city: Faker::Address.city,
    state: Faker::Address.state,
    date_of_birth: Faker::Date.birthday(min_age: 18, max_age: 65),
    father_name: Faker::Name.name,
    government_id_number: Faker::Number.number(digits: 12),
    user_id: user.id
  )

  photo_fut = fetch_waifu_image_async
  gov_id_fut = fetch_waifu_image_async

  photo_url = photo_fut.value!
  gov_id_url = gov_id_fut.value!

  if photo_url
    record.photo.attach(io: URI.open(photo_url), filename: "photo_#{i + 1}#{File.extname(photo_url)}")
  end

  if gov_id_url
    record.government_id_photo.attach(io: URI.open(gov_id_url), filename: "gov_id_#{i + 1}#{File.extname(gov_id_url)}")
  end

  log("📇 Created record for #{record.name} (User ID: #{user.id})")
  record
end

# Attendance
users.each do |user|
  20.times do
    in_time = Faker::Time.between(from: 3.days.ago, to: 1.day.ago)
    has_out_time = [true, false].sample
    out_time = has_out_time ? Faker::Time.between(from: in_time + 1.hour, to: in_time + 8.hours) : nil

    record = records.sample
    attendance = Attendance.create!(
      user_id: user.id,
      record_id: record.id,
      in_time: in_time,
      out_time: out_time
    )

    in_fut = fetch_waifu_image_async
    out_fut = fetch_waifu_image_async if has_out_time

    in_url = in_fut.value!
    out_url = out_fut&.value!

    if in_url
      attendance.in_photo.attach(io: URI.open(in_url), filename: "in_#{attendance.id}#{File.extname(in_url)}")
    end

    if has_out_time && out_url
      attendance.out_photo.attach(io: URI.open(out_url), filename: "out_#{attendance.id}#{File.extname(out_url)}")
    end

    log("🕒 Attendance logged for #{user.email} | In: #{in_time} | Out: #{out_time || '❌'}")
  end
end

puts "✅ Seeding completed!"
