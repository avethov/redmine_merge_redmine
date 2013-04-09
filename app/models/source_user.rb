# KS - tried to use inheritance but it did not work as a result of ActiveRecord
#      using the "type" column and the name of the class to put together a query such as:
#
#   SELECT "users".* FROM "users" WHERE "users"."type" IN ('SourceUser')
# -- Note the "SourceUser" type in the query -- the only way I know not to have ActiveRecord not use the type 
#    column would be to tell it to overwrite Base.inheritance_column but this could cause issues for Redmine.
#
#class SourceUser < SourcePrincipal

class SourceUser < ActiveRecord::Base
  include SecondDatabase
  self.table_name = "users"
  has_and_belongs_to_many :groups, :class_name => 'SourceGroup', :join_table => 'groups_users', :foreign_key => 'user_id', :association_foreign_key => 'group_id'

  # ActiveRecord allows class to pull entries out of the database
  def self.migrate
    puts "Starting migration of Users"
    all(:conditions => {:type => "User"}).each do |source_user| 
    #    all.each do |source_user|
      next if User.find_by_mail(source_user.mail)
      next if User.find_by_login(source_user.login)
#      next if source_user.type == "AnonymousUser"
#      # Added by KS - don't migrate groups here, done in SourceGroup
#      next if source_user.type == "Group"
      
      User.create!(source_user.attributes) do |u|
        u.login = source_user.login
        u.admin = source_user.admin
        u.hashed_password = source_user.hashed_password
      end
    end
    puts "Done migrating Users"
  end
end
