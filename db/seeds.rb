# Create an admin user if no admin exists
unless User.exists?(email: 'admin@example.com')
  User.create!(
    email: 'admin@example.com',
    password: 'password123',  # Set your desired password here
    password_confirmation: 'password123',
    role: 1
  )
end
