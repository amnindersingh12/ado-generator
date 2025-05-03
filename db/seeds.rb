# db/seeds.rb

# Clear existing records to avoid duplication during development
puts "Clearing existing records..."
Record.destroy_all

# Helper method to get the mikey.png image path
def get_mikey_image_path
  path = Rails.root.join("app", "assets",  "mikey.png")
  
  # Check if the image exists and is valid
  unless File.exist?(path)
    puts "Error: mikey.png not found at #{path}"
    return nil
  end

  unless File.size(path) > 0
    puts "Error: mikey.png is empty at #{path}"
    return nil
  end

  path
end

# Create sample records
puts "Creating sample records..."

# Sample employee names
names = [
  "John Smith",
  "Emma Johnson",
  "Michael Williams",
  "Sophia Brown",
  "James Jones",
  "Olivia Davis",
  "Robert Miller",
  "Ava Wilson",
  "William Moore",
  "Isabella Taylor"
]

# Check if user with ID 1 exists, create one if not
user = User.find_by(id: 1)
unless user
  puts "Warning: No user found with ID 1. Creating a default user..."
  user = User.create!(
    id: 1,
    email: "default@example.com",
    password: "password123",
    name: "Default User"
  )
  puts "Created default user with ID 1: #{user.email}"
end

# Get the mikey.png image path
mikey_image_path = get_mikey_image_path

if mikey_image_path
  # Create records with different timestamps
  names.each_with_index do |name, index|
    begin
      # Create a record with check-in details and user_id: 1
      record = Record.new(
        name: name,
        in_time: Time.current - rand(1..48).hours,
        user_id: user.id
      )

      # Add check-out details for some records (e.g., 70% chance)
      record.in_photo.attach(io: File.open(File.join(Rails.root,'app/assets/images/mikey.png')), filename: 'mikey.png')

     
      
      record.save!
      puts "Created record for #{name} associated with user ID #{user.id}"

    rescue ActiveStorage::IntegrityError => e
      puts "Failed to attach photo for #{name}: #{e.message}"
    rescue StandardError => e
      puts "Failed to create record for #{name}: #{e.message}"
    end
  end

  puts "Seed completed successfully! Created #{Record.count} records for user ID #{user.id}."
else
  puts "Error: Could not create seeds because mikey.png was not found or invalid."
end