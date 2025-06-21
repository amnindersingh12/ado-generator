# frozen_string_literal: true

require 'open-uri'
require 'faker'

Rails.logger.debug '🌱 Starting seed...'

def sample_image_io
  image_path = Rails.root.glob('db/seeds/images/*').sample
  File.open(image_path)
end

# === USERS ===
admin_user = User.create!(
  email: 'dev@dev.com',
  password: 'rootroot',
  role: 'admin'
)
Rails.logger.debug { "✅ Created admin user: #{admin_user.email}" }

# === PRIMARY RECORDS ===
primary_records = 10.times.map do
  record = Record.create!(
    name: Faker::Name.name,
    contact_number: Faker::Number.number(digits: 10),
    address: Faker::Address.full_address,
    pincode: Faker::Number.number(digits: 6),
    city: Faker::Address.city,
    state: Faker::Address.state,
    date_of_birth: Faker::Date.birthday(min_age: 18, max_age: 65),
    father_name: Faker::Name.name,
    government_id_number: Faker::Number.number(digits: 12),
    user_id: admin_user.id,
    is_guest: false
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

    Rails.logger.debug { "📸 Attached photos for Record ##{record.id} - #{record.name}" }
  rescue StandardError => e
    Rails.logger.debug { "⚠️ Failed to attach image for Record ##{record.id}: #{e.message}" }
  end

  record
end

# === GUEST RECORDS ===
guest_records = primary_records.flat_map do |parent_record|
  rand(1..2).times.map do
    guest = Record.create!(
      name: Faker::Name.name,
      contact_number: Faker::Number.number(digits: 10),
      address: parent_record.address,
      pincode: parent_record.pincode,
      city: parent_record.city,
      state: parent_record.state,
      date_of_birth: Faker::Date.birthday(min_age: 5, max_age: 17),
      father_name: parent_record.name,
      government_id_number: Faker::Number.number(digits: 12),
      user_id: admin_user.id,
      parent_record_id: parent_record.id,
      is_guest: true
    )

    Rails.logger.debug { "👥 Guest created for #{parent_record.name}: #{guest.name}" }
    guest
  end
end

all_records = primary_records + guest_records

# === ATTENDANCE ===
User.all.each do |user|
  10.times do
    in_time = Faker::Time.between(from: 90.days.ago, to: 2.days.ago)
    out_time = Faker::Time.between(from: in_time + 1.hour, to: in_time + 10.hours)

    attendance = Attendance.new(
      user_id: user.id,
      record_id: all_records.sample.id,
      in_time: in_time,
      out_time: out_time,
      purpose: Faker::Lorem.sentence(word_count: 8)
    )

    begin
      attendance.save!
      Rails.logger.debug { "🕒 Attendance for #{user.email} (Record ##{attendance.record_id}) created" }
    rescue StandardError => e
      Rails.logger.debug { "⚠️ Attendance creation failed: #{e.message}" }
    end
  end
end

Rails.logger.debug '✅ Seeding completed with relationships and guest records!'
