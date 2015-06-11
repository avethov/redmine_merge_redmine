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

  def self.find_target(user, options = { fail: true })
    target = User.find_by_mail(user.mail) || User.find_by_login(user.login)
    if target.nil? && options[:fail]
      fail "No target found with mail `#{user.mail}` or login `#{user.login}`"
    end
    target
  end

  # ActiveRecord allows class to pull entries out of the database
  def self.migrate
    all(:conditions => { :type => 'User' }).each do |source_user|
      if SourceUser.find_target(source_user)
        puts "  Skipping existing user #{source_user}"
        next
      end

      User.create!(source_user.attributes) do |u|
        u.login = source_user.login
        u.admin = source_user.admin
        u.hashed_password = source_user.hashed_password
      end
    end
  end
end
