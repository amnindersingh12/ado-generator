# to download and store images locally
# rake waifu:download

require 'open-uri'
require 'faker'

puts "🌱 Starting seed..."

def sample_image_io
  image_path = Dir[Rails.root.join('db', 'seeds', 'images', '*')].sample
  File.open(image_path)
end

# Create Users
users = 1.times.map do
  user = User.create!(
    email: Faker::Internet.unique.email,
    password: 'password123',
    role: %w[user admin].sample
  )
  puts "✅ Created user: #{user.email} (#{user.role})"
  user
end

# Create Records with photos
records = 10.times.map do |i|
  record = Record.create!(
    name: Faker::Name.name,
    contact_number: Faker::PhoneNumber.phone_number,
    address: Faker::Address.full_address,
    pincode: Faker::Address.zip_code,
    city: Faker::Address.city,
    state: Faker::Address.state,
    date_of_birth: Faker::Date.birthday(min_age: 18, max_age: 65),
    father_name: Faker::Name.name,
    government_id_number: Faker::Number.number(digits: 12),
    user_id: users.sample.id
  )

  begin
    record.photo.attach(
      io: sample_image_io,
      filename: "record_photo_#{record.id}.jpg"
    )
    record.government_id_photo.attach(
      io: sample_image_io,
      filename: "gov_id_photo_#{record.id}.jpg"
    )
    puts "📷 Attached photos for record: #{record.name}"
  rescue => e
    puts "⚠️ Failed to attach image to record #{record.id}: #{e.message}"
  end

  record
end

# Create multiple attendance entries for each user
users.each do |user|
  10.times do
    in_time = Faker::Time.between(from: 90.days.ago, to: 1.day.ago)
    out_time = Faker::Time.between(from: in_time + 1.hour, to: in_time + 8.hours)

    attendance = Attendance.create!(
      user_id: user.id,
      record_id: records.sample.id,
      in_time: in_time,
      out_time: out_time
    )

    begin
      attendance.in_photo.attach(
        io: sample_image_io,
        filename: "in_photo_#{attendance.id}.jpg"
      )
      attendance.out_photo.attach(
        io: sample_image_io,
        filename: "out_photo_#{attendance.id}.jpg"
      )
      puts "🕒 Attendance created for #{user.email} at #{in_time.strftime('%F %T')}"
    rescue => e
      puts "⚠️ Failed to attach attendance image #{attendance.id}: #{e.message}"
    end
  end
end

puts "✅ Seeding completed successfully!"
