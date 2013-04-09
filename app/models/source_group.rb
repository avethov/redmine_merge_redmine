# Added by Ken Sperow
# Groups are stored in the "users" table with a type of "group" and the group name stored in the lastname field - a hack in my opinion
# Users are migrated in the SourceUser class
#
# KS - tried to use inheritance but it did not work as a result of ActiveRecord
#      using the "type" column and the name of the class to put together a query such as:
#
#   SELECT "users".* FROM "users" WHERE "users"."type" IN ('SourceUser')
# -- Note the "SourceUser" type in the query -- the only way I know not to have ActiveRecord not use the type 
#    column would be to tell it to overwrite Base.inheritance_column but this could cause issues for Redmine.
#
#class SourceGroup < SourcePrincipal

class SourceGroup < ActiveRecord::Base
  include SecondDatabase
  self.table_name = "users"
  
  has_and_belongs_to_many :users, :class_name => 'SourceUser', :join_table => 'groups_users', :foreign_key => 'group_id', :association_foreign_key => 'user_id'

  # ActiveRecord allows class to pull entries out of the database
  def self.migrate
    puts "Starting migration of Groups"
    all(:conditions => {:type => "Group"}).each do |source_group|

      puts "group name: #{source_group.lastname}"

      # Don't migrate a group that already exists
      next if Group.find_by_lastname(source_group.lastname)

      puts "Migrating group name: #{source_group.lastname}"
      
      # For some unknown reason the code is not seeing the has_and_belongs_to_many entry above that tells it to use
      # the SourceUser class, which should load the data from the "source" database.
      # The following line will force it to connect to the "source" database
      source_group.users.establish_connection :source_redmine
      
      source_group.users.each do |source_group_user|
         puts "group user: #{source_group_user.login}"         
      end
      
      # Don't migrate groups that already exist
      next if Group.find_by_lastname(source_group.lastname)
      
      puts "About to migrate group name: #{source_group.lastname}"
      Group.create!(source_group.attributes) do |g|
        source_group.users.establish_connection :source_redmine
        source_group.users.each do |source_group_user|
#           puts "group user: #{source_group_user.login}"
          # Note that I have to switch the connection back to "production" for the User class
          User.establish_connection :production
          migrated_user = User.find_by_login(source_group_user.login)  
#          puts "migrated group user: #{migrated_user.login} #{migrated_user.id} "
          g.users << migrated_user if migrated_user
        end
      end
    end
    puts "Done migrating Groups"
  end
end
