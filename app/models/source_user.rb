class SourceUser < ActiveRecord::Base
  include SecondDatabase
  set_table_name :users

  # ActiveRecord allows class to pull entries out of the database
  def self.migrate
    puts "Starting migration of Users"
    all.each do |source_user|
      next if User.find_by_mail(source_user.mail)
      next if User.find_by_login(source_user.login)
      next if source_user.type == "AnonymousUser"
      
      User.create!(source_user.attributes) do |u|
        u.login = source_user.login
        u.admin = source_user.admin
        u.hashed_password = source_user.hashed_password
      end
    end
    puts "Done migrating Users"
  end
end
