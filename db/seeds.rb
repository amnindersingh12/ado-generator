# frozen_string_literal: true

# rake waifu:download

require 'open-uri'
require 'faker'

Rails.logger.debug '🌱 Starting seed...'

def sample_image_io
  image_path = Rails.root.glob('db/seeds/images/*').sample
  File.open(image_path)
end

# Create Users
users = 1.times.map do
  user = User.create!(
    email: Faker::Internet.email,
    password: 'rootroot',
    role: 'admin'
  )
  Rails.logger.debug { "✅ Created user: #{user.email} (#{user.role})" }
  user
end

# Create Records with photos
records = 10.times.map do |_i|
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
      filename: "record_photo_#{record.id}.png"
    )
    record.government_id_photo.attach(
      io: sample_image_io,
      filename: "gov_id_photo_#{record.id}.png"
    )
    Rails.logger.debug { "📷 Attached photos for record: #{record.name}" }
  rescue StandardError => e
    Rails.logger.debug { "⚠️ Failed to attach image to record #{record.id}: #{e.message}" }
  end

  record
end

# Create multiple attendance entries for each user
users.each do |user|
  10.times do
    in_time = Faker::Time.between(from: 90.days.ago, to: 1.day.ago)
    out_time = Faker::Time.between(from: in_time + 1.hour, to: in_time + 12.hours)
    purpose = Faker::Lorem.sentence(word_count: 3)
    attendance = Attendance.new(
      user_id: user.id,
      record_id: records.sample.id,
      in_time: in_time,
      out_time: out_time,
      purpose: purpose
    )

    begin
      # Randomly attach either in_photo, out_photo, or both
      attach_type = %i[both].sample

      case attach_type
      when :in
        attendance.in_photo.attach(
          io: sample_image_io,
          filename: "in_photo_#{attendance.id}.png"
        )
      when :out
        attendance.out_photo.attach(
          io: sample_image_io,
          filename: "out_photo_#{attendance.id}.png"
        )
      when :both
        attendance.in_photo.attach(
          io: sample_image_io,
          filename: "in_photo_#{attendance.id}.png"
        )
        attendance.out_photo.attach(
          io: sample_image_io,
          filename: "out_photo_#{attendance.id}.png"
        )
      end

      attendance.save!
      Rails.logger.debug do
        "🕒 Attendance created for #{user.email} at #{in_time.strftime('%F %T')} with #{attach_type} photo(s)"
      end
    rescue StandardError => e
      Rails.logger.debug { "⚠️ Failed to create attendance or attach image: #{e.message}" }
    end
  end
end

Rails.logger.debug '✅ Seeding completed successfully!'
